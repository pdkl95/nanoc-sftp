module Nanoc::Sftp
  module FileUtil
    def with_sftp(&block)
      ask_for_login_fields if missing_required_login_fields?
      msg "openening a connection to #{@user}@#{host}"
      msg "option: #{login_options.inspect}"
      retval = 1
      Net::SFTP.start(@host, @user, login_options) do |sftp|
        @sftp = sftp
        retval = block.call
        @sftp = nil
      end
      retval
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
  end
end
