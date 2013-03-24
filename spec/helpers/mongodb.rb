module Mongodb
  MONGOD_PATH = "mongod"

  class Instance

    def initialize
      system "pkill mongod"
      sleep(0.1)
      start
    end

    def start
      p "START"
      @pid = spawn("mongod")
      sleep(0.1)
    end

    def stop
      p "STOP"
      Process.kill("SIGINT", @pid)
      sleep(0.1)
    end
  end
end