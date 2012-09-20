module Nanoc::Sftp
  module FileSets
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

    def updated_files
      @updated_files ||= compiled_files.intersection(existing_files)
    end

    def new_files
      @new_files ||= compiled_files.difference(updated_files)
    end

    def stale_files
      @stale_files ||= existing_files.difference(updated_files)
    end

    def full_changeset
      [].tap do |list|
        list.concat(updated_files.map{ |fn| [fn, :update] })
        list.concat(    new_files.map{ |fn| [fn, :new   ] })
        list.concat(  stale_files.map{ |fn| [fn, :stale ] })
      end.sort do |a,b|
        a.first <=> b.first
      end
    end
  end
end
