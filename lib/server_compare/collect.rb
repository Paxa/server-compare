require 'net/ssh'
require 'colorize'
require 'server_compare/server_state'

class Collect
  attr_reader :state

  def initialize(ssh_host, ssh_user, ssh_options = {})
    @ssh_host = ssh_host
    @ssh_user = ssh_user
    @ssh_options = ssh_options

    @state = ServerState.new
  end

  def collect
    @state.host_name = ssh_exec("hostname")
    @state.kernel = ssh_exec("uname -r")
    @state.distro = ssh_exec("cat /etc/centos-release")
    @state.packages = ssh_exec("rpm -qa").split("\n")
    @state.users_groups = ssh_exec("for user in $(awk -F: '{print $1}' /etc/passwd); do groups $user; done").split("\n")
  end

  def ssh_connection
    @ssh_connection ||= Net::SSH.start(@ssh_host, @ssh_user, @ssh_options)
  end

  def ssh_exec(command)
    puts_pending("SSH: #{command}")

    # ssh_connection.exec(command)
    # puts_complete("SSH: #{command}")

    result = ssh_exec_command(command)

    if result[:success]
      puts_complete("SSH: #{command}")
    else
      puts_failed("SSH: #{command}")
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