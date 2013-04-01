module Mongodb
  MONGOD_PATH = "mongod"

  class Instance
    def initialize(opts)
      @cmd = [MONGOD_PATH]
      opts.each do |k,v|
        @cmd << "--#{k}"
        @cmd << v
      end
      shtdwn
      start
    end

    def shtdwn
      system "#{@cmd * ' '} --shutdown"
    end

    def start
      return @pid if @pid
      @pid = spawn(*@cmd, out: "/dev/null")
      sleep(1)
    end

    def stop
      return unless @pid
      Process.kill("SIGINT", @pid)
      Process.waitpid(@pid)
      @pid = nil
    end
  end
end