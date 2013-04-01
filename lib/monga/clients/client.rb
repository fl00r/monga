module Monga::Clients
  class Client
    extend Forwardable

    def_delegators :@connection_pool, :aquire_connection, :send_command, :primary?, :connected?
    
    attr_reader :connection_pool

    def initialize(opts={})
      opts[:pool_size] ||= 1
      @connection_pool = Monga::ConnectionPool.new(opts)
    end

    def [](db_name)
      Monga::Database.new(self, db_name)
    end

    def find_primary!
      @connection_pool.connections.each do |conn|
        conn.is_master?(self)
      end
    end
  end
end