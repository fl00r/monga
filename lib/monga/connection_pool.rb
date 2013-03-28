module Monga
  class ConnectionPool < Monga::Connection
    attr_reader :connections

    def initialize(opts={})
      @connections = []
      pool_size = opts.delete :pool_size

      raise ArgumentError, "you should specify pool_size option" unless pool_size

      pool_size.times do
        @connections << Monga::Connection.new(opts)
      end
    end

    # Aquires connection with min responses in queue.
    # If there are a number of equal connections pick random one.
    # If all connections disconnected take disconnected one.
    def aquire_connection
      connected = @connections.select(&:connected?)
      if connected.any?
        min = connected.min_by{ |c| c.responses.size }.responses.size
        conns = connected.select{ |c| c.responses.size == min }
        conns.sample
      else
        @connections.sample
      end
    end

    def reconnect(host, port)
      @connections.each do |conn|
        conn.reconnect(host, port)
      end
    end
  end
end