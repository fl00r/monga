module Monga::Connections
  # ProxyConnection accepts requests when ReplicaSetClient didn't know where to send requests.
  # I.E. when client is just initialized here is no any established connections,
  # so client waits for the connection ready to accept requests.
  # Also, when primary is down it will collect request while nodes are voting.
  # Importaint to say, that requests will be stored in this object only for `timeout` period.
  class EMProxyConnection
    # Pause while searching server in seconds
    WAIT = 0.05
    
    def initialize(client)
      @client = client
      @timeout = @client.timeout
      @requests = {}
    end

    # If timeout is defined then collect request and start timeout.
    # If timeout is not defined or zero then return exception.
    def send_command(msg, request_id = nil, &cb)
      if @timeout && @timeout > 0 
        @requests[request_id] = [msg, cb] if cb
        set_timeout unless @pending_timeout
        find_server! unless @pending_server
      else
        error = Monga::Exceptions::Disconnected.new "Can't find appropriate server (all disconnected)"
        cb.call(error) if cb
      end
    end

    # If timeout happend send exception to all collected requests.
    def set_timeout
      @pending_timeout = EM::Timer.new(@timeout) do
        @timeout_happend = true
      end
    end

    def timeout_happend
      @timeout_happend = false
      @pending_timeout = false
      @pending_server = false
      @requests.keys.each do |request_id|
        msg, cb = @requests.delete request_id
        error = Monga::Exceptions::Disconnected.new "Can't find appropriate server (all disconnected)"
        cb.call(error) if cb
      end
    end

    # Find server unless server is found
    def find_server!(i = 0)
      @pending_server = true
      if @pending_timeout && !@timeout_happend
        size = @client.clients.size
        client = @client.clients[i%size]
        client.force_status! do |status|
          if status == :primary && [:primary, :primary_preferred, :secondary_preferred].include?(@client.read_pref)
            server_found!
          elsif status == :secondary && [:secondary, :primary_preferred, :secondary_preferred].include?(@client.read_pref)
            server_found!
          else
            EM::Timer.new(WAIT) do
              find_server!(i+1)
            end
          end
        end
      else
        timeout_happend
      end
    end

    # YEEEHA! Send all collected requests back to client
    def server_found!
      @pending_server = false
      @pending_timeout.cancel if @pending_timeout
      @pending_timeout = nil
      @timeout_happend = false
      @requests.keys.each do |request_id|
        msg, blk = @requests.delete request_id
        @client.aquire_connection.send_command(msg, request_id, &blk)
      end
    end
  end
end