module ServerCompare::CLI
  extend self

  def command_collect(server)

    if server.include?("@")
      ssh_user, ssh_host = server.split("@")

      collector = ServerCompare::Collect.new(ssh_host, ssh_user, CONFIG)
      collect_and_commit(config, collector, server_name)
      return
    end

    if server == ":all"
      config = load_config
      config.servers.each do |server_name, server_info|
        puts "-- Processing #{server_name}..."
        puts
        collector = ServerCompare::Collect.from_config(server_info)
        collect_and_commit(config, collector, server_name)
      end
      return
    end

    if server.start_with?(":")
      server_name = server.sub(/^:/, '')

      config = load_config
      validate_server_name_in_config(config, server_name)
      collector = ServerCompare::Collect.from_config(config.servers[server_name])
      collect_and_commit(config, collector, server_name)
    else
      raise Help
    end
  end

  def load_config
    unless File.exist?("./servers.yml")
      puts "Can not find file ./servers.yml"
      puts
      raise Help
    end

    ServerCompare::ConfigFile.new("./servers.yml")
  end

  def validate_server_name_in_config(config, server_name)
    unless config.servers[server_name]
      puts "Unknown server: #{server_name}, registered: #{config.servers.keys.join(", ")}"
      puts
      raise Help
    end
  end

  def collect_and_commit(config, collector, server_name)
    collector.collect
    collector.disconnect
    puts collector.state.summary

    if config && !CONFIG[:dry]
      storage = ServerCompare::GitStorage.for_server(config.repo_dir, server_name, config.repo_url)
      storage.init_repo#(server_name)
      storage.check_remote_changes
      storage.remove_all_files
      collector.state.write_files(storage.path)
      storage.commit_changes(server_name)
    end
  end

end