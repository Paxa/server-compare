require "FileUtils"
require "yaml"

class ServerCompare::ServerState
  attr_accessor :host_name
  attr_accessor :distro
  attr_accessor :kernel
  attr_accessor :packages
  attr_accessor :users_groups
  attr_accessor :users_info

  def summary
    puts "Host:     #{@host_name}"
    puts "System:   #{@distro}"
    puts "          #{@kernel}"
    puts "Packages: #{@packages && @packages.size}"
    puts "Users:    #{@users_groups && @users_groups.size}"
  end

  def write_files(path)
    #FileUtils.mkdir_p(path)
    #FileUtils.rm_r(Dir.glob("#{path}/*")) # if file already exists

    Dir.chdir(path) do
      File.open("host.txt", 'w:utf-8') {|f|   f.write(@host_name) }
      File.open("distro.txt", 'w:utf-8') {|f| f.write(@distro) }
      File.open("kernel.txt", 'w:utf-8') {|f| f.write(@kernel) }

      FileUtils.mkdir_p("packages")

      @packages.each do |package|
        match = package.match(/^(.+?)\-(\d.+)$/)
        package_name = match[1]
        package_version = match[2]

        File.open("packages/#{package_name}.txt", 'w:utf-8') {|f| f.write(package_version) }
      end

      FileUtils.mkdir_p("users")

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

        File.open("users/#{user}.yml", 'w:utf-8') {|f| f.write(YAML.dump(user_hash)) }
      end
    end
  end
end