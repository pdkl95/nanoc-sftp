module Nanoc::Sftp
  module FileUtil
    def with_sftp(&block)
      ask_for_login_fields if missing_required_login_fields?
      msg "openening a connection to #{user}@#{host}"
      msg "option: #{login_options.inspect}"
      retval = 1
      Net::SFTP.start(host, @user, login_options) do |sftp|
        @sftp = sftp
        retval = block.call
        @sftp = nil
      end
      retval
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
      print "." ; spin delay

      print msg_erase
    end

    def create_remote_directory!(path, dir)
      @created_directories ||= {}
      return if @created_directories[dir]

      unless sftp.dir[path, dir].first == dir
        fullpath = "#{path}/#{dir}"
        puts "mkdir(#{fullpath.inspect})"
        sftp.mkdir(fullpath)
      end
      @created_directories[dir] = true
    end

    def upload_file(local_path, remote_path)
      puts "UPLOADING: #{local_path}"
      puts "   --> TO: #{remote_path}"
      if self.dry_run?
        simulate_upload!(local_path)
      else
        sftp.upload! local_path, remote_path
      end
      puts "ok"
    end

    def upload!(file)
      dir = File.dirname(file)
      dirlist = []
      while dir != '.'
        dirlist.push(dir)
        dir = File.dirname(dir)
      end
      while dirlist.length > 0
        create_remote_directory! path, dirlist.pop
      end
      upload_file "#{srcdir}/#{file}", "#{path}/#{file}"
    end

    def expunge!(file)
      dst = "#{path}/#{file}"
      puts "EXPUNGING: #{dst.inspect}"
      sftp.remove!(dst)
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
