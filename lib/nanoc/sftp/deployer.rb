# encoding: utf-8

require 'awesome_print'
module Nanoc::Sftp
  class Deployer < ::Nanoc::Extra::Deployer

    REQUIRED_FIELDS = [:host, :user, :pass, :path]
    OPTIONAL_FIELDS = [:port]
    FIELDS = REQUIRED_FIELDS + OPTIONAL_FIELDS

    attr_accessor *FIELDS

    SSL_TRANSPORT_OPTIONS = {
      :compression => true
    }

    attr_reader :sftp, :srcdir, :topdir, :site

    def initialize(*args)
      super *args

      FIELDS.each do |field|
        instance_variable_set "@#{field}", config[field].to_s
      end

      @target = config[:target] || 'staging'
      @target.upcase!

      @srcdir = File.expand_path(self.source_path)
      puts "srcdir=#{@srcdir}"
      @topdir = File.expand_path File.join(@srcdir, '/..')
      puts "topdir=#{@topdir}"
      Dir.chdir(@topdir) do
        @site = Nanoc::Site.new('.')
      end
    end

    def compiled_files_array
      site.items.map do |item|
        item.reps.map do |rep|
          rep.raw_path.sub /^#{self.source_path}\//, ''
        end
      end.flatten.compact.select do |f|
        File.file? "#{self.source_path}/#{f}"
      end
    end

    def compiled_files
      @compiled_files ||= Set.new compiled_files_array

    end

    def existing_files
      @existing_files ||= Set.new
    end

    def clobbered_files
      @clobbered_files ||= compiled_files.intersection(existing_files)
    end

    def new_files
      @new_files ||= compiled_files.difference(clobbered_files)
    end

    def stale_files
      @stale_files ||= existing_files.difference(clobbered_files)
    end

    def run
      require 'net/sftp'

      stty_backup = `stty -g`

      Signal.trap("INT") do
        system "stty #{stty_backup}"
        exit(1)
      end


      with_sftp do
        list_existing_files!
        verify_upload_set!
        deploy_files!
      end

      msg "Finished!"
    ensure
      system "stty #{stty_backup}"
    end

    def list_existing_files!
      list_recursive path do |entry|
        existing_files.add entry
      end
    end

    def verify_upload_set!
      ap compiled_files
      ap existing_files
    end

    def deploy_files!
      compiled_files.each do |file|
        upload! "#{srcdir}/#{file}", "#{path}/#{file}"
      end
    end

    #SPIN="\\|/-"
    #SPIN="◐◓◑◒"
    #SPIN="◢◣◤◥"
    #SPIN="⚀⚁⚂⚃⚄⚅"
    SPIN="▟▄▙▌▛▀▜▐"
    #SPIN="▖▘▝▗"
    #SPIN="◴◷◶◵◰◳◲◱"

    #SPIN="┤┘┴└├┌┬┐"
    #SPIN="▉▊▋▌▍▎▏▎▍▌▋▊▉"
    #SPIN="▁▃▄▅▆▇█▇▆▅▄▃"
    #SPIN="←↖↑↗→↘↓↙"
    def spin(n)
      @spinval ||= 0
      print '* '
      while n > 0.1
        @spinval += 1
        @spinval = 0 if @spinval >= SPIN.length
        c = SPIN[@spinval,1]
        print "\b\b#{c} "
        sleep 0.1
        n -= 0.1
      end
      print "\b\b  \b\b"
      sleep n
    end

    def upload!(local_path, remote_path)
      puts "UPLOADING: #{local_path}"
      puts "   --> TO: #{remote_path}"
      if self.dry_run?
        msg = "<dry_run - simulating upload> "
        print msg
        n = 0.2 + File.size(local_path).to_f / (2**20).to_f
        n*=0.8
        len = 1 + msg.length + n.to_i
        bs = ("\b" * len) + (" " * len) + ("\b" * len)
        while n > 1.0
          print "."
          spin 1.0
          n -= 1.0
        end
        print "."
        spin n
        print bs
      else
        sftp.upload! local_path, remote_path
      end
      puts "ok"
    end

    def skip_entry?(entry)
      entry.directory? ||
        entry.name.start_with?('.')
    end

    def filtered_yield(enum)
      enum.each do |entry|
        yield entry.name unless skip_entry? entry
      end
    end

    def list(dir, &block)
      filtered_yield sftp.dir.foreach(dir).to_enum, &block
    end

    def glob(*args, &block)
      filtered_yield sftp.dir.glob(*args).to_enum, &block
    end

    def list_recursive(dir, &block)
      glob dir, "**/*", &block
    end

    def ask_for_login_fields_with_highline
      @host = ask("What is the <%= color('hostname', BOLD) %> " +
        "of the SFTP server?\n"
        ) { |q|
        q.default = @host
        q.validate = /^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$/

        q.whitespace = :remove
      }

      @post = ask("What <%= color('Port') %> is the SFTP server using? ",
        "(leave it blank to use the standard port, 22/tcp)"
        ) { |q|
        q.default = @port.to_s
        q.whitespace = :remove
        q.validate = /^\d{2,5}$/
      }

      @user = ask("What <%= color('username') %> to login as? "
        ) { |q|
        q.default = @user
        q.whitespace = :strip
        q.validate = /^\w+$/
      }

      @pass = ask("Please enter your <%= color('password', BOLD) %> now,\n" +
        "to login with SFTP \"<%= color('#{@user}', BOLD) %>" +
        "@<%= color('#{@host}', BOLD) %>:<%= color('#{@port}', BOLD) %>\":"
        ) { |q|
        q.echo = false
        q.whitespace = nil
      }
    end

    def ask_for_login_fields_with_yad
      dialog_text = [
        '<span size="large">',
        'Deploying to the ',
        '<span font-weight="bold" foreground="#c24545">',
        @target,
        '</span> server</span>'
      ].join('')

      args = [
        "--form",
        "--buttons-layout=edge",
        "--button=gtk-apply:0",
        "--button=gtk-cancel:1",
        "--on-load",
        "--borders=5",
        "--text=#{dialog_text}",
        "--title=Deploying website to the #{@target} server",
        "--image=upload-media",
        "--window-icon=upload-media",
        "--align=right",
        "--columns=2",
        "--separator=|",
        "--field=Hostname",
        "--field=Port:NUM",
        "--field=Username",
        "--field=Password:H",
        "thoughtnoise.net",
        "2501!22..65535!1!0",
        "telleena",
        "" # empty pass
      ]
      cmd = args.map { |x| "'#{x}'" }.join(' ')
      cmd = "#{@yad} #{cmd}"

      output = IO.popen(cmd, 'r') do |prog|
        prog.read.split(/\|/)
      end
      ret = $?.to_i

      @host = output[0]
      @port = output[1].to_i
      @user = output[2]
      @pass = output[3]

      puts @host
    end

    def ask_for_login_fields
      if have_yad?
        ask_for_login_fields_with_yad
      else
        ask_for_login_fields_with_highline
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

    def with_sftp(&block)
      ask_for_login_fields if missing_required_login_fields?
      msg "openening a connection to #{@user}@#{host}"
      msg "option: #{login_options.inspect}"
      Net::SFTP.start(@host, @user, login_options) do |sftp|
        @sftp = sftp
        block.call
        @sftp = nil
      end
    end

    private

    def load_highline_if_possible
      require 'highline/import'
      @have_hl = true
    rescue LoadError
      @have_hl = false
    end

    def have_highline?
      load_highline_if_possible unless defined? @have_hl
      @have_hl
    end

    def msg(*args)
      msg = args.flatten.join(' ')
      if have_highline?
        say msg
      else
        puts msg
      end
    end

    def have_yad?
      ENV['PATH'].split(/:/).each do |dir|
        file = "#{dir}/yad"
        if File.executable?(file)
          @yad = file
          return @yad
        end
      end
      false
    end

    def blank?(x)
      x = x.to_s
      x.nil? || x.empty?
    end
  end
end

