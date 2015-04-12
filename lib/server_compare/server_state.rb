class ServerState
  attr_accessor :host_name
  attr_accessor :distro
  attr_accessor :kernel
  attr_accessor :packages
  attr_accessor :users_groups

  def summary
    puts "Host:     #{@host_name}"
    puts "System:   #{@distro}"
    puts "          #{@kernel}"
    puts "Packages: #{@packages && @packages.size}"
    puts "Users:    #{@users_groups && @users_groups.size}"
  end
end