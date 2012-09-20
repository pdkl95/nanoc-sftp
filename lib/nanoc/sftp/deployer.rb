# encoding: utf-8

require 'open3'
require 'nanoc/sftp/file_sets'
require 'nanoc/sftp/file_util'
require 'nanoc/sftp/gui'
require 'nanoc/sftp/gui/highline'
require 'nanoc/sftp/gui/yad'

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
        if verify_upload_set!
          deploy_files!
          msg "Finished!"
        else
          msg "Quitting; server remains unchanged!"
        end
      end
    end

    def list_existing_files!
      list_recursive path do |entry|
        existing_files.add entry
      end
    end

    def verify_upload_set!
      if have_yad?
        verify_with_yad
      else
        true
      end
    end

    def deploy_files!
      compiled_files.each do |file|
        upload! "#{srcdir}/#{file}", "#{path}/#{file}"
      end
    end

    def simulate_upload!(file_path)
      msg = "<dry_run - simulating upload> "
      print msg

      file_size = File.size(file_path)
      file_mb   = file_size.to_f / (2**20).to_f
      min_delay = 0.15
      per_mb    = 0.8
      delay     = min_delay + (per_mb * file_mb)
      msglen    = 1 + msg.length + delay.to_i
      msg_bs    = "\b" * msglen
      msg_sp    =  " " * msglen
      msg_erase = "#{msg_bs}#{msg_sp}#{msg_bs}"

      while delay > 1.0
        delay -= 1.0
        print "." ; spin 1.0
      end
      print "." ; spin n

      print msg_erase
    end

    def upload!(local_path, remote_path)
      puts "UPLOADING: #{local_path}"
      puts "   --> TO: #{remote_path}"
      if self.dry_run?
        simulate_upload!(local_path)
      else
        sftp.upload! local_path, remote_path
      end
      puts "ok"
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

