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

    # Aquires connection with min responses in queue
    # if there are a number of equal connections pick random one
    def aquire_connection
      min = @connections.min_by{ |c| c.responses.size }.responses.size
      conns = @connections.select{ |c| c.responses.size == min }
      conn = conns.sample
      conn
    end
  end
end