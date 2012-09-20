module Nanoc::Sftp::UI
  module Highline
    def load_highline_if_possible
      require 'highline/import'
      @have_hl = true
    rescue LoadError
      @have_hl = false
    end

    def have_highline?
      load_highline_if_possible unless defined? @have_hl
      puts "Have highline: #{@have_hl}"
      @have_hl
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

    def verify_with_highline
      raise "FIXME"
    end
  end
end
