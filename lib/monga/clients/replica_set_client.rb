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
        case server
        when Hash
          Monga::Clients::SingleInstanceClient.new(opts.merge(server))
        when String
          Monga::Clients::SingleInstanceClient.new(opts.merge(server: server))
        end
      end

      @requests = {}
      @proxy_connection = Monga::Connection.proxy_connection_class(opts[:type], self)
    end

    # Aquires connection due to read_pref option
    def aquire_connection(start = nil, &blk)
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
      if server
        blk.call server
      else
        find_server! unless start
        start ||= Time.now.to_i
        if start + @timeout > Time.now.to_i
          ::EM.add_timer(0.01) do
            aquire_connection(start, &blk)
          end
        else
          raise "Can't aquire server"
        end
      end
    end

    def find_server!(i = 0)
      size = clients.size
      client = clients[i%size]
      client.force_status! do |status|
        if status == :primary && [:primary, :primary_preferred, :secondary_preferred].include?(read_pref)
        elsif status == :secondary && [:secondary, :primary_preferred, :secondary_preferred].include?(read_pref)
        else
          EM::Timer.new(0.001) do
            find_server!(i+1)
          end
        end
      end
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