require "yaml"

class ServerCompare::ConfigFile
  def initialize(file)
    @file = file
    file_content = File.open(file, 'r:utf-8', &:read)
    @content = YAML.load(file_content).freeze
  end

  def repo_dir
    @content['repo_dir']
  end

  def repo_url
    @content['repo_url']
  end

  def servers
    @content['servers'] || {}
  end

  def source_path
    @file
  end
end