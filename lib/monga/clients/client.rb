module Monga::Clients
  class Client
    extend Forwardable

    def_delegators :@connection, :aquire_connection, :send_command
    
    attr_reader :connection

    def initialize(opts={})
      if opts[:pool_size]
        @connection = Monga::ConnectionPool.new(opts)
      else
        @connection = Monga::Connection.new(opts)
      end
    end

    def [](db_name)
      Monga::Database.new(self, db_name)
    end
  end
end