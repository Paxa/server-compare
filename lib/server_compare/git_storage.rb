require "FileUtils"
require 'shellwords'

class ServerCompare::GitStorage
  attr_reader :path
  attr_reader :branch

  def self.for_server(path, server)
    new(File.join(path, server), server)
  end

  def initialize(path, branch)
    @path = path
    @branch = branch
  end

  def init_repo
    unless created?
      FileUtils.mkdir_p(@path)
      Dir.chdir(@path) do
        `git init .`
      end
    end
    set_branch(@branch)
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

  def commit_changes
    Dir.chdir(@path) do
      status = `git status`
      if status =~ /nothing to commit/
        puts "No changes"
      else
        `git add .`
        `git commit -m 'state #{Time.now}'`
      end
    end
  end

  def push(remote_url)
    set_remote(remote_url)
    Dir.chdir(@path) do
      `git push origin '#{Shellwords.escape(@branch)}'`
    end
  end

  def set_remote(remote_url)
    Dir.chdir(@path) do
      remotes = `git remote -v`
      unless remotes.include?(remote_url)
        `git remote add origin '#{Shellwords.escape(remote_url)}'`
      end
    end
  end

end