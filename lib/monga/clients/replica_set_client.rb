module Monga::Clients
  class ReplicaSetClient
    attr_reader :read_pref, :timeout, :clients

    # ReplicaSetClient creates SingleInstanceClient to each server.
    # Accepts
    # * servers - you could pas them as a array of servers (['1.1.1.1:27017', '1.1.1.2:27017']), or as a array of hashes: ([{host: '1.1.1.1', port: 27017}, {host: '1.1.1.2', port: 27017}])
    # * read_pref - read preferrence (:primary, :primary_preferred, :secondary, :secondary_preferred)
    # * pool_size - connection pool size to each server
    # * type - connection type (:em/:sync/:block)
    def initialize(opts)
      @timeout = opts[:timeout]
      @read_pref = opts[:read_pref] || :primary

      servers = opts.delete :servers
      @clients = servers.map do |server|
        c = case server
        when Hash
          Monga::Clients::SingleInstanceClient.new(opts.merge(server))
        when String
          h, p = server.split(":")
          o = { host: h, port: p.to_i }
          Monga::Clients::SingleInstanceClient.new(opts.merge(o))
        end
        c.force_status!
        c
      end

      @proxy_connection = Monga::Connection.proxy_connection_class(opts[:type], self)
    end

    # Aquires connection due to read_pref option
    def aquire_connection
      server = case @read_pref
      when :primary
        primary
      when :secondary
        secondary
      when :primary_preferred
        primary || secondary
      when :secondary_preferred
        secondary || primary
      when :nearest
        raise ArgumentError, "nearest read preferrence is not implemented yet"
      else
        raise ArgumentError, "`#{@read_pref}` is not valid read preferrence, use :primary, :primary_preferred, :secondary, or :secondary_preferred"
      end

      server || @proxy_connection
    end

    # Fetch primary server
    def primary
      pr = @clients.detect{ |c| c.primary? && c.connected? }
      pr.aquire_connection if pr
    end

    # Fetch secondary server
    def secondary
      sc = @clients.select{ |c| c.secondary? && c.connected? }.sample
      sc.aquire_connection if sc
    end
  end
end