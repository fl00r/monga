module Monga::Clients
  class ReplicaSetClient
    extend Forwardable
    
    def_delegators :pick_client, :aquire_connection, :send_command

    def initialize(opts = {})
      @read_pref = opts.delete(:read_pref) || :primary
      @servers = opts[:servers]
      raise ArgumentError, "servers option is not passed or empty" if @servers.empty?

      @primary = Monga::Client.new(opts.merge({connection_type: :primary, client: self}))
      @secondaries = (@servers.size - 1).times.map do
        Monga::Client.new(opts.merge({connection_type: :secondary, client: self}))
      end
    end

    def pick_client
      case @read_pref
      when :primary
        primary
      when :primary_preferred
        p, s = primary, secondary
        if p.connected?
          p
        elsif s.connected?
          s
        else
          p
        end
      when :secondary
        secondary
      when :secondary_preferred
        p, s = primary, secondary
        if s.connected?
          s
        elsif p.connected?
          p
        else
          s
        end
      when :nearest
        fail "not implemented mode"
      else
        fail "undefined read_pref mode"
      end
    end

    def primary
      @primary
    end

    # If all secondaries are disconnected, choose disconnected one
    def secondary
      fail "Here is no any secondary to choose" if @secondaries.empty?
      
      secondary = @secondaries.select{ |c| c.aquire_connection.connected? }.sample
      secondary ||= @secondaries.sample
    end
  end
end