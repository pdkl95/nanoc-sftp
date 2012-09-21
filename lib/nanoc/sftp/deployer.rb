# encoding: utf-8

require 'open3'
require 'nanoc/sftp/file_sets'
require 'nanoc/sftp/file_util'
require 'nanoc/sftp/ui'
require 'nanoc/sftp/ui/highline'
require 'nanoc/sftp/ui/yad'

module Nanoc::Sftp
  class Deployer < ::Nanoc::Extra::Deployer
    include Nanoc::Sftp::FileSets
    include Nanoc::Sftp::FileUtil
    include Nanoc::Sftp::UI
    include Nanoc::Sftp::UI::Highline
    include Nanoc::Sftp::UI::Yad

    REQUIRED_FIELDS = [:host, :user, :pass, :path]
    OPTIONAL_FIELDS = [:port, :spinner]
    FIELDS = REQUIRED_FIELDS + OPTIONAL_FIELDS

    attr_accessor *FIELDS

    SSL_TRANSPORT_OPTIONS = {
      :compression => true
    }

    attr_reader :sftp, :srcdir, :topdir, :site

    def blank?(x)
      x = x.to_s
      x.nil? || x.empty?
    end

    def initialize(*args)
      super *args

      FIELDS.each do |field|
        instance_variable_set "@#{field}", config[field].to_s
      end

      @target = config[:target] || 'staging'
      @target.upcase!

      @spinner = :fancy if @spinner.nil? || @spinner == ''
      @spinner = @spinner.to_sym if @spinner.is_a? String

      @srcdir = File.expand_path(self.source_path)
      @topdir = File.expand_path File.join(@srcdir, '/..')

      Dir.chdir(@topdir) do
        @site = Nanoc::Site.new('.')
      end
    end

    def run
      require 'net/sftp'

      stty_backup = `stty -g`

      Signal.trap("INT") do
        system "stty #{stty_backup}"
        exit(1)
      end

      deploy!

    ensure
      system "stty #{stty_backup}"
    end

    def deploy!
      with_sftp do
        list_existing_files!
        if verify_deploy_plan!
          msg "Deploy plan verified - sending files to #{host} ..."
          deploy_files!
          msg "Finished!"
        else
          msg "*** CANCEL ***"
          msg "Quitting; server remains unchanged!"
        end
      end
    end

    def list_existing_files!
      list_recursive path do |entry|
        existing_files.add entry
      end
    end

    def deploy_files!
      msg "Sending *NEW* files..."
      new_files.each do |file|
        upload! file
      end

      msg "Sending *UPDATED* files..."
      updated_files.each do |file|
        upload! file
      end

      msg "Removing *STALE* files..."
      stale_files.each do |file|
        expunge! file
      end
    end

    def missing_required_login_fields?
      REQUIRED_FIELDS.each do |field|
        val = send(field).to_s
        blank?(val) and return true
      end
      false
    end

    def login_options
      SSL_TRANSPORT_OPTIONS.tap do |opt|
        opt[:password] = @pass
        opt[:port]     = @port unless blank? @port
      end
    end
  end
end

