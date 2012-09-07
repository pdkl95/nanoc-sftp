# -*- encoding: utf-8 -*-

require File.expand_path('../lib/nanoc/sftp/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "nanoc-sftp"
  gem.version       = Nanoc::Sftp::VERSION
  gem.summary       = %q{Nanoc deploy plugin For places where a full SSH login is disabled, but simple chroot-jail SFTP is allowed. The stock rsync method is recommended over this, if possible.}
  gem.description   = %q{An SFTP-only deploy script for nanoc}
  gem.license       = "MIT"
  gem.authors       = ["Brent Sanders"]
  gem.email         = "git@thoughtnoise.net"
  gem.homepage      = "http://github.dom/pdkl95/nanoc-sftp"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'bundler', '~> 1.0'
  gem.add_development_dependency 'rake', '~> 0.8'
  gem.add_development_dependency 'rdoc', '~> 3.0'
  gem.add_development_dependency 'rubygems-tasks', '~> 0.2'
end
