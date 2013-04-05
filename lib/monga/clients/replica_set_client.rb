module Monga::Clients
  class ReplicaSetClient
    class ProxyConnection
      include EM::Deferrable

      def initialize(client)
        @client = client
      end

      def send_command(msg, request_id=nil, &cb)
        callback do
          connection = @client.aquire_connection
          connection.send_command(msg, request_id, &cb)
        end
      end
    end

    include EM::Deferrable

    attr_reader :servers, :clients

    def initialize(opts = {})
      @read_pref = opts.delete(:read_pref) || :primary
      @servers = opts.delete(:servers)
      raise ArgumentError, "servers option is not passed or empty" if @servers.empty?

      @clients = @servers.map do |server|
        Monga::Client.new(server.merge(opts))
      end

      @proxy_connection = ProxyConnection.new(self)
    end

    def [](db_name)
      Monga::Database.new(self, db_name)
    end

    def aquire_connection
      server ||= case @read_pref
      when :primary
        primary
      when :secondary
        secondary
      when :primary_preferred
        primary || secondary
      when :secondary_preferred
        secondary || primary
      when :nearest
        fail "unimplemented read_pref mode"
      else
        fail "read_pref is undefined"
      end

      if server
        if @deferred_status != :succeeded
          set_deferred_status :succeeded 
          @proxy_connection.set_deferred_status :succeeded
        end
      else
        if @deferred_status == :succeeded
          set_deferred_status nil
          @proxy_connection.set_deferred_status nil
        end
      end

      server || @proxy_connection
    end

    def primary
      prim = @clients.detect{ |c| c.primary? && c.connected? }
      unless prim
        find_primary!
      end
      prim
    end

    def secondary
      @clients.select{ |c| !c.primary? && c.connected? }.sample
    end

    def find_primary!
      unless @pending_primary
        @pending_primary = true
        @clients.each{ |c| c.find_primary! }
        EM.add_timer(0.1) do
          if primary
            aquire_connection
            @pending_primary = false
          else
            @pending_primary = false
            find_primary!
          end
        end
      end
    end
  end
end