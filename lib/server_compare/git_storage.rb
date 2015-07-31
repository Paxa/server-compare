require "FileUtils"
require 'shellwords'

class ServerCompare::GitStorage
  attr_reader :path
  attr_reader :branch
  attr_accessor :remote_url

  CONFIG_BRANCH = "config"

  def self.for_server(path, server, remote_url = nil)
    new(File.join(path, server), server, remote_url)
  end

  def self.for_config(path, remote_url)
    new(File.join(path, CONFIG_BRANCH), CONFIG_BRANCH, remote_url)
  end

  def initialize(path, branch, remote_url = nil)
    @path = path
    @branch = branch
    @remote_url = remote_url
  end

  def init_repo
    unless created?
      FileUtils.mkdir_p(@path)
      Dir.chdir(@path) do
        `git init .`
      end
    end
    set_branch#(@branch)
  end

  def check_remote_changes
    set_remote
    Dir.chdir(@path) do
      `git pull origin #{branch}`
    end
  end

  def created?
    File.directory?("#{@path}/.git")
  end

  def set_branch
    Dir.chdir(@path) do
      current_branch = `git rev-parse --abbrev-ref HEAD`.strip
      if current_branch != @branch
        `git co -b '#{Shellwords.escape(@branch)}'`
      end
    end
  end

  def remove_all_files
    Dir.chdir(@path) do
      files = Dir.glob("*").select {|f| !f.start_with?(".git") }
      FileUtils.rm_r(files)
    end
  end

  def has_changes?
    status = nil
    Dir.chdir(@path) do
      status = `git status`
    end
    return status !~ /nothing to commit/
  end

  def commit_changes(server_name = @branch)
    Dir.chdir(@path) do
      status = `git status`
      if status =~ /nothing to commit/
        puts "No changes"
      else
        `git add . -u`
        `git commit -m '#{server_name} @ #{Time.now}'`
      end
    end
  end

  def push
    set_remote
    Dir.chdir(@path) do
      `git push origin '#{Shellwords.escape(@branch)}'`
    end
  end

  def set_remote
    Dir.chdir(@path) do
      remotes = `git remote -v`
      unless remotes.include?(@remote_url)
        `git remote add origin '#{Shellwords.escape(@remote_url)}'`
      end
    end
  end

end