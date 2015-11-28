require 'net/ssh'
require 'net/scp'
require 'colorize'
require 'server_compare'
require 'resolv'

class ServerCompare::Collect
  attr_reader :state

  def self.from_config(hash)
    hash = hash.dup
    if hash["pem"]
      hash[:keys] = hash.delete("pem")
    end
    options = {}
    hash.each {|k, v| options[k.to_sym] = v }
    new(hash.delete('host'), hash.delete('user'), hash)
  end

  def initialize(ssh_host, ssh_user, ssh_options = {})
    @ssh_host = ssh_host
    @ssh_user = ssh_user
    @host_options = ssh_options

    @state = ServerCompare::ServerState.new
  end

  def collect
    @state.host_name = ssh_exec("hostname")
    @state.host_ip = Resolv.getaddress(@ssh_host)
    @state.kernel = ssh_exec("uname -r")
    @state.distro = ssh_exec("cat /etc/centos-release")
    @state.packages = ssh_exec("rpm -qa").split("\n")
    @state.users_groups =
      ssh_exec("for user in $(awk -F: '{print $1}' /etc/passwd); do groups $user; done").split("\n")
    @state.users_info = ssh_exec("cat /etc/passwd")

    @state.ifconfig = ssh_exec("ifconfig | grep 'Link encap:\\|inet addr\\|inet6 addr'")
    @state.cpuinfo = ssh_exec("cat /proc/cpuinfo")
    @state.lscpu = ssh_exec("lscpu")
    @state.swapinfo = ssh_exec("swapon -a -s")
    @state.diskinfo = ssh_exec("lsblk")
    @state.meminfo = ssh_exec("cat /proc/meminfo | grep 'MemTotal\\|SwapTotal'")

    @state.mounts = ssh_exec("mount -l")
    @state.iptables = ssh_exec("iptables -S")

    @state.auto_load_services = ssh_exec("chkconfig --list")

    crontabs_cmd = %{for user in $(cut -f1 -d: /etc/passwd); do } +
                     %{echo "~$user"; crontab -u $user -l 2>&1 | awk '$0="    "$0' ; done}
    @state.users_crontab = ssh_exec(crontabs_cmd)

    changed_configs_cmd = 'rpm -Vva --nodeps --noscripts 2>&1 | grep -v "^\.\{8\}" | grep "[[:blank:]]/etc/"'
    @state.changed_files = ssh_exec(changed_configs_cmd)

    # S.5....T.  c /etc/ssh/sshd_config
    # S.5....T.  c /etc/securetty
    # S.5....T.  c /etc/sudoers
    # S.5....T.  c /etc/yum.conf
    # S.5....T.  c /etc/rc.d/rc.local
    # S.5....T.  c /etc/sysconfig/init
    changed_files_lines = @state.changed_files.split(/\n/)
    changed_files_lines.each do |file_line|
      file = file_line.split(/^.+\s{2}c?\s(.*)/).last
      next if file =~ /^\s*$/ || file_line.start_with?("missing")

      @host_options['preserve_files'] ||= []
      unless @host_options['preserve_files'].include?(file)
        @host_options['preserve_files'] << file
      end
    end


    if @host_options['preserve_files']
      safe_files = @host_options['preserve_files'].map do |file|
        Shellwords.escape(file)
      end
      stat_files_cmd = %{stat -c "%n | %a | %U:%G | %F | %y" #{@host_options['preserve_files'].join(" ")}}
      @state.preserve_files_meta = ssh_exec(stat_files_cmd).split("\n")

      @state.preserve_files_meta.each do |line|
        file_data = line.split("|").map(&:strip)
        file_stat = Hash[[:name, :access, :owner, :type, :mtime].zip(file_data)]

        if file_stat[:type] == "directory"
          next
        end
        @state.preserve_files << [file_stat[:name], scp_file(file_stat[:name])]
      end
    end
  end

  def ssh_connection
    ENV['LC_CTYPE'] = "en_US.UTF-8"
    @ssh_connection ||= Net::SSH.start(@ssh_host, @ssh_user, ssh_options)
  end

  def scp_file(remote_file)
    puts_pending("SCP: #{remote_file}")
    data = Net::SCP::download!(@ssh_host, @ssh_user, remote_file, nil, ssh: ssh_options)
    puts_complete("SCP: #{remote_file}")
    data
  rescue => error
    puts_failed("SCP: #{remote_file}")
    puts error.message.red
  end

  def ssh_options
    options = {}
    #command[:send_env] = "LC_CTYPE"
    options[:keys] = @host_options[:keys] || @host_options['keys']
    options
  end

  TIME_SIGN = "🕐"

  def ssh_exec(command)
    puts_pending("SSH: #{command}")

    # ssh_connection.exec(command)
    # puts_complete("SSH: #{command}")

    start_time = Time.now

    result = ssh_exec_command(command)

    spent_time = Time.now - start_time
    if spent_time > 5 # 5 seconds
      time = " #{TIME_SIGN}  #{spent_time.round(3)}sec"
    else
      time = ""
    end

    if result[:success]
      puts_complete("SSH: #{command}#{time}")
    else
      puts_failed("SSH: #{command}#{time}")
    end

    if result[:stderr].size > 0
      puts result[:stderr].red
    end

    result[:stdout]
  end

  def ssh_exec_command(command)
    stdout_data = ""
    stderr_data = ""
    exit_code = nil
    exit_signal = nil

    ssh_connection.open_channel do |channel|
      channel.exec(command) do |ch, success|
        unless success
          abort "FAILED: couldn't execute command (ssh.channel.exec)"
        end
        channel.on_data do |ch,data|
          stdout_data += data
        end

        channel.on_extended_data do |ch,type,data|
          stderr_data += data
        end

        channel.on_request("exit-status") do |ch,data|
          exit_code = data.read_long
        end

        channel.on_request("exit-signal") do |ch, data|
          exit_signal = data.read_long
        end
      end
    end
    ssh_connection.loop

    # [stdout_data, stderr_data, exit_code, exit_signal]
    {success: exit_code == 0, stdout: stdout_data, stderr: stderr_data, code: exit_code }
  end

  def disconnect
    @ssh_connection.close if @ssh_connection
  end

  @@clear = "\e[K".freeze

  def puts_pending(msg)
    print "\r#{@@clear}"
    print "* #{msg}".yellow
  end

  def puts_complete(msg)
    print "\r#{@@clear}"
    print "# #{msg}\n".green
  end

  def puts_failed(msg)
    print "\r#{@@clear}"
    print "# #{msg}\n".red
  end

end