require 'timeout'

module Monga::Connections
  class ProxyConnection
    # Pause while searching server in seconds
    WAIT = 0.3
    
    def initialize(client)
      @client = client
      @timeout = @client.timeout
      @requests = {}
    end

    # If timeout is defined then collect request and start timout.
    # If timout is not defined or zero then return exception.
    def send_command(msg, request_id = nil, &cb)
      if @timeout && @timeout > 0 
        @requests[request_id] = [msg, cb] if cb
        set_timeout
      else
        error = Monga::Exceptions::Disconnected.new "Can't find appropriate server (all disconnected)"
        cb.call(error) if cb
      end
    end

    # If timeout happend send exception to all collected requests.
    def set_timeout
      @not_found = true
      Timeout::timeout(@timeout) do
        while @not_found
          find_server!
          sleep(WAIT)
        end
      end
    rescue Timeout::Error => e
      raise Monga::Exceptions::Disconnected.new "Can't find appropriate server (all disconnected)"
    end

    # Find server unless server is found
    def find_server!
      @client.clients.each do |client|
        client.force_status! do |status|
          if status == :primary && [:primary, :primary_preferred, :secondary_preferred].include?(@client.read_pref)
            @pending_server = false
            server_found!
          elsif status == :secondary && [:secondary, :primary_preferred, :secondary_preferred].include?(@client.read_pref)
            @pending_server = false
            server_found!
          end
        end
      end
    end

    # YEEEHA! Send all collected requests back to client
    def server_found!
      @not_found = false
      @requests.keys.each do |request_id|
        msg, blk = @requests.delete request_id
        @client.aquire_connection.send_command(msg, request_id, &blk)
      end
    end
  end
end