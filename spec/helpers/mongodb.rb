module Mongodb
  MONGOD_PATH = "mongod"

  class Instance
    def initialize(opts)
      @opts = opts
      @cmd = [MONGOD_PATH]
      opts.each do |k,v|
        @cmd << "--#{k}"
        @cmd << v.to_s
      end
      clean_lock
      shtdwn
      start
    end

    def clean_lock
      lock = @opts[:dbpath] + "/mongod.lock"
      File.rm(lock)
    rescue
      # ok
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

  class ReplicaSet
    def initialize(ports, opts={})
      opts[:replSet] ||= "rs1"
      opts[:dbpath] ||= "/tmp/mongodb/rs0"
      @instances = {}
      ports.each.with_index do |prt, i|
        dbpath = opts[:dbpath] + "-#{i}"
        o = opts.merge({ port: prt[:port], dbpath: dbpath })
        @instances[prt[:port]] = Instance.new(o)
      end
      @client = Monga::ReplicaSetClient.new(servers: REPL_SET_PORTS)
    end

    def primary
      @client.primary
    end
  end
end