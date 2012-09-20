# encoding: utf-8

module Nanoc::Sftp
  module UI
    SPIN = {
      :basic => "\\|/-",
      :fancy => "▟▄▙▌▛▀▜▐"
#      :fancy => "\u259F\u2584\u2599\u258C\u259B\u2580\u259C\u2590"
    }

    def spin(n, style = spinner)
      @spinval ||= 0
      print '* '
      while n > 0.1
        @spinval += 1
        @spinval = 0 if @spinval >= SPIN.length
        c = SPIN[style][@spinval,1]
        print "\b\b#{c} "
        sleep 0.1
        n -= 0.1
      end
      print "\b\b  \b\b"
      sleep n
    end

    def msg(*args)
      msg = args.flatten.join(' ')
      if have_highline?
        say msg
      else
        puts msg
      end
    end

    def ask_for_login_fields
      if have_yad?
        ask_for_login_fields_with_yad
      else
        ask_for_login_fields_with_highline
      end
    end
  end
end
