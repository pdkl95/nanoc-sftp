require 'pp'

module Nanoc::Sftp::UI
  module Yad
    def have_yad?
      if @yad.nil? ; then
        ENV['PATH'].split(/:/).each do |dir|
          file = "#{dir}/yad"
          if File.executable?(file)
            @yad = file
            return @yad
          end
        end
        false
      else
        @yad
      end
    end

    def verify_deploy_plan_yad!
      text = "<span size='x-large'>Deployment Plan</span>\n<span>Sould the following changes be made on the server?</span>"
      args = [
        "--list",
        "--column=CHK:CHK",
        "--column=@back@",
        "--column=IMG:IMG",
        "--column=Status:TEXT",
        "--column=TIP:TIP",
        "--column=File:TEXT",
        "--hide-column=5",
        "--search-column=6",
        "--checklist",
        "--print-all",
        "--title=Deployment Plan",
        "--image=upload-media",
        "--window-icon=upload-media",
#        "--no-headers",
        "--width=600",
        "--height=400",
        "--image-on-top",
        "--text=#{text}",
        "--buttons-layout=spread",
        "--button=gtk-execute:0",
        "--button=gtk-cancel:1",
        "--borders=3"
      ]
      cmd = args.map { |x| "\"#{x}\"" }.join(' ')
      cmd = "#{@yad} #{cmd}"

      Open3.popen3(cmd) do |stdin,stdout,stderr,wait_thr|
        stdin.write(full_changeset.map do |x|
            fn, status = *x
            case status
            when :new    then ['TRUE',  '#CCFFD1', 'gtk-new',     'NEW',    "creates: #{path}/#{fn}"]
            when :update then ['TRUE',  '#FFD0D2', 'gtk-save-as', 'UPDATE', "updates: #{path}/#{fn} with #{srcdir}/#{fn}"]
            when :stale  then ['FALSE', '#FFF899', 'gtk-delete',  'STALE',  "removes: #{path}/#{fn}"]
            else raise "unknown status: #{status}"
            end.concat(["#{fn}"])
          end.flatten.join("\n"))
        stdin.flush
        stdin.close
        @plan = stdout.readlines.map do |line|
            Hash[ [:ok, :bgcolor, :status, :tooltip, :file].zip line.split(/\|/) ]
        end
        @success = wait_thr.value.success?
      end

      if @success
        @plan.each do |x|
          if x[:ok] == 'FALSE'
            case x[:status]
            when    'NEW' then     new_files
            when 'UPDATE' then updated_files
            when  'STALE' then   stale_files
            else raise "bad status value: #{x[:status]}"
            end.delete x[:file]
          end
        end
      end

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
        @host,
        @port,
        @user,
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
    end
  end
end
