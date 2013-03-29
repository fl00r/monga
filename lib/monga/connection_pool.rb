module Monga
  class ConnectionPool < Monga::Connection
    extend Forwardable

    def_delegators :aquire_connection, :send_command

    attr_reader :connections

    def initialize(opts={})
      @connections = []
      pool_size = opts.delete :pool_size

      pool_size.times do
        @connections << Monga::Connection.new(opts)
      end
    end

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

    def primary?
      conn = aquire_connection
      conn ? conn.master? : false
    end

    def connected?
      @connections.any?(&:connected?)
    end
  end
end