module Monga::Clients
  class SingleInstanceClient
    # Status will inform Replica Set client of current client's status 
    # primary/secondary/nil
    attr_reader :status

    def initialize(opts)
      opts[:pool_size] ||= 1
      @connection_pool = Monga::ConnectionPool.new(opts)
    end

    # If single connection then return it.
    # If connection pool then aquire connection from pool.
    # If connection is not connected, then status will be setted to nil.
    def aquire_connection
      conn = @connection_pool.aquire_connection
      @status = nil unless conn.connected?
      conn
    end

    def connected?
      aquire_connection.connected?
    end

    # Check status of connection.
    # If ReplicaSetClient can't find connection with read_pref status 
    # it will send foce_status! to all clients while timout happend
    # or while preferred status will be returned
    def force_status!
      if connected?
        conn = aquire_connection
        conn.is_master? do |status|
          @connection_pool.connections.each{ |c| c.primary = true  if status == :primary}
          @status = status
          yield(@status) if block_given?
        end
      else
        yield(@status) if block_given?
      end
    end

    def primary?
      @status == :primary
    end

    def secondary?
      @status == :secondary
    end
  end
end