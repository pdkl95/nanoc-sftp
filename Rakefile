# encoding: utf-8

require 'rubygems'

begin
  require 'bundler'
rescue LoadError => e
  warn e.message
  warn "Run `gem install bundler` to install Bundler."
  exit -1
end

begin
  Bundler.setup(:development)
rescue Bundler::BundlerError => e
  warn e.message
  warn "Run `bundle install` to install missing gems."
  exit e.status_code
end

require 'rake'

require 'rubygems/tasks'
class Gem::Tasks::Install
  def install(path)
    run 'gem', 'install', '-q', '--no-rdoc', '--no-ri', path
  end
end
task :validate

Gem::Tasks.new(:scm => false) do |tasks|
  
end

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  rdoc.title = "nanoc-sftp"
end
task :doc => :rdoc
