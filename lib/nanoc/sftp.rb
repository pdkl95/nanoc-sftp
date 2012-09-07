require 'nanoc'

module Nanoc
  module Sftp
    autoload 'Deployer', 'nanoc/sftp/deployerp'
    Nanoc::Extra::Deployer.register '::Nanoc::Sftp::Deployer', :sftp
  end
end
