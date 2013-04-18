module Monga
  class ConnectionPool
    attr_reader :connections
    
    def initialize(opts)
      pool_size = opts.delete :pool_size

      @connections = []
      pool_size.times do
        @connections << Monga::Connection.new(opts)
      end
    end

    # Aquires random connection with min waiting responses among connected.
    # Otherwise return random disconnected one.
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
  end
end