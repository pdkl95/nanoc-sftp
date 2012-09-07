# encoding: utf-8

module Nanoc::Sftp
  class Deployer < ::Nanoc::Extra::Deployer

    REQUIRED_FIELDS = [:host, :user, :pass]
    OPTIONAL_FIELDS = [:port]
    LOGIN_FIELDS = REQUIRED_FIELDS + OPTIONAL_FIELDS

    attr_accessor *LOGIN_FIELDS

    SSL_TRANSPORT_OPTIONS = {
      :compression => true
    }

    def run
      require 'net/sftp'

      stty_backup = `stty -g`

      Signal.trap("INT") do
        system "stty #{stty_backup}"
        exit(1)
      end


      LOGIN_FIELDS.each do |field|
        instance_variable_set "@#{field}", self.config[field].to_s
      end

      @target = (self.config[:target] || 'staging').upcase

      with_sftp do |sftp|
        list "/" do |entry|
          puts entry
        end
      end

      msg "Finished!"
    ensure
      system "stty #{stty_backup}"
    end

    def list(dir)
      @sftp.dir.foreach("/") do |entry|
        next if entry.name =~ /^[.]/
        yield entry.name
      end
    end

    def ask_for_login_fields_with_highline
      @host = ask("What is the <%= color('hostname', BOLD) %> " +
        "of the SFTP server?\n"
        ) { |q|
        q.default = @host
        q.validate = /^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$/

        q.whitespace = :remove
      }

      @post = ask("What <%= color('Poer') %> is the SFTP server using? ",
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
        puts field
        val = send(field).to_s
        puts val
        blank?(val) and reeturn true
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
      return true unless defined? x
      return true if x.nil?
      return true if x.respond_to? :length && x.length == 0
      false
    end
  end
end

