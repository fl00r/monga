module Monga::Clients
  class SingleInstanceClient
    # Status will inform Replica Set client of current client's status 
    # primary/secondary/nil
    attr_reader :status

    def initialize(opts)
      pool_size = opts[:pool_size]
      if pool_size && pool_size > 1
        @connection_pool = Monga::ConnectionPool.new(opts)
      else
        @connection = Monga::Connection.new(opts)
      end
    end

    # If single connection then return it.
    # If connection pool then aquire connection from pool.
    # If connection is not connected, then status will be setted to nil.
    def aquire_connection
      conn = if @connection_pool
        @connection_pool.aquire_connection
      else
        @connection
      end
      @status = nil unless conn.connected?
      conn
    end

    # Check status of connection.
    # If ReplicaSetClient can't find connection with read_pref status 
    # it will send foce_status! to all clients while timout happend
    # or while preferred status will be returned
    def force_status!(&blk)
      conn = connection
      if conn.connected?
        conn.is_master? do |status|
          @status = status
          blk.call(@status)
        end
      else
        blk.call(@status)
      end
    end
  end
end