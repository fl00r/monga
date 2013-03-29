# How it works
# Replica Set tries to establish connections to all passed servers.
# Till no connection established it queues al queries inside it's

module Monga::Clients
  class ReplicaSetClient
    include EM::Deferrable

    attr_reader :servers, :clients

    def initialize(opts = {})
      @read_pref = opts.delete(:read_pref) || :primary
      @servers = opts.delete(:servers)
      raise ArgumentError, "servers option is not passed or empty" if @servers.empty?

      @clients = @servers.map do |server|
        Monga::Client.new(server.merge(opts))
      end
    end

    def [](db_name)
      Monga::Database.new(self, db_name)
    end

    def send_message(*args)
      connection = aquire_connecion
      if connection
        set_deferred_status :succeeded if @deferred_status != :succeeded
      else
        set_deferred_status nil if @deferred_status == :succeeded
      end
      callback do
        (connection || aquire_connecion).send_message(*args)
      end
    end

    def aquire_connecion
      case @read_pref
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
    end

    def primary
      prim = @clients.detect{ |c| c.primary? && c.connected? }
      unless prim && @pending_primary
        find_primary!
      end
      prim
    end

    def secondary
      @clients.select{ |c| !c.primary? && c.connected? }.sample
    end

    def find_primary!
      @pending_primary = true
      @clients.each{ |c| c.find_primary! }
      EM.add_timer(0.1) do
        if primary
          @pending_primary = false
        else
          find_primary!
        end
      end
    end
  end
end