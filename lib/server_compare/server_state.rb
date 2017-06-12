require "FileUtils"
require "yaml"

class ServerCompare::ServerState
  attr_accessor :host_name
  attr_accessor :host_ip
  attr_accessor :distro
  attr_accessor :kernel
  attr_accessor :packages
  attr_accessor :auto_load_services

  attr_accessor :users_groups
  attr_accessor :users_info
  attr_accessor :users_crontab

  # HARDWARE
  attr_accessor :cpuinfo
  attr_accessor :diskinfo
  attr_accessor :meminfo
  attr_accessor :lscpu

  # SYSCONF
  attr_accessor :ifconfig
  attr_accessor :iptables
  attr_accessor :mounts
  attr_accessor :swapinfo

  # FILES
  attr_accessor :preserve_files
  attr_accessor :preserve_files_meta

  attr_accessor :changed_files

  def initialize
    @preserve_files = []
    @preserve_files_meta = []
  end

  def summary
    puts "Host:     #{@host_name.strip} (#{@host_ip})"
    puts "System:   #{@distro}"
    puts "          #{@kernel}"
    puts "Packages: #{@packages && @packages.size}"
    puts "Users:    #{@users_groups && @users_groups.size}"
  end

  def write_files(path)
    #FileUtils.mkdir_p(path)
    #FileUtils.rm_r(Dir.glob("#{path}/*")) # if file already exists

    Dir.chdir(path) do
      write_file("hostname.txt", @host_name)
      write_file("host_ip.txt", @host_ip)
      write_file("distro.txt", @distro)
      write_file("kernel.txt", @kernel)
      write_file("auto_load_services.txt", @auto_load_services)


      write_file("hardware/cpuinfo.txt", @cpuinfo)
      write_file("hardware/lscpu.txt", @lscpu)
      write_file("hardware/meminfo.txt", @meminfo)
      write_file("hardware/diskinfo.txt", @diskinfo)

      write_file("sysconf/ifconfig.txt", @ifconfig)
      write_file("sysconf/iptables.txt", @iptables)
      write_file("sysconf/mounts.txt", @mounts)

      write_file("files/__changed_files.txt", @changed_files)

      # Remove 'Used' from `swapon` output
      swapinfo_wo_used = ""
      @swapinfo.lines.each do |line|
        parts = line.split("\t")
        parts.delete_at(3)
        swapinfo_wo_used << parts.join("\t") + "\n"
      end

      write_file("sysconf/swapinfo.txt", swapinfo_wo_used)

      @packages.each do |package|
        match = package.match(/^(.+?)\-(\d.+)$/)
        package_name = match[1]
        package_version = match[2]

        write_file("packages/#{package_name}.txt", package_version)
      end

      crontabs = parse_crontabs
      puts crontabs['railsapp']

      @users_groups.each do |line|
        match = line.match(/^(.+)\s:\s(.*)$/)
        user = match[1]
        groups = match[2].split(/\s+/).sort
        info = @users_info.lines.detect {|l| l.start_with?("#{user}:") }

        if info
          info = info.split(":")
          home_dir = info[info.size - 2]
          shell_name = info[info.size - 1]
        end

        user_hash = {
          'groups' => groups.join(" "),
          'home_dir' => home_dir.strip,
          'shell_name' => shell_name.strip
        }

        if crontabs[user]
          user_hash['crontab'] = crontabs[user]
        end

        write_file("users/#{user}.yml", YAML.dump(user_hash))
      end

      preserve_files_meta.each do |line|
        file_data = line.split("|").map(&:strip)
        stat = Hash[[:name, :access, :owner, :type, :mtime].zip(file_data)]
        write_file("files_meta/#{stat[:name]}", line)
      end

      preserve_files.each do |file, content|
        write_file("files/#{file}", content)
      end
    end
  end

  def parse_crontabs
    sections = ("\n" + @users_crontab).split(/\n^~/)
    per_user = {}
    sections.each do |section|
      next if section == ""

      lines = section.lines
      user = lines.shift.strip
      if lines.size == 1 && lines[0] =~ /^\s+no crontab for/
        next
      else
        per_user[user] = lines.map {|l| l.sub(/^\s{4}/, '').rstrip }.join("\n")
      end
    end

    return per_user
  end

  def write_file(path, content)
    dir = File.dirname(path)
    if dir != "."
      FileUtils.mkdir_p(dir)
    end
    File.open(path, 'wb') {|f| f.write(content) }
  rescue => error
    puts "Error writing file #{path}"
    puts "#{error.class}: #{error.message}"
    puts error.backtrace
  end
end