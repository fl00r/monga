module Monga::Connections
  # ProxyConnection accepts requests when ReplicaSetClient didn't know where to send requests.
  # I.E. when client is just initialized here is no any established connections,
  # so client waits for the connection ready to accept requests.
  # Also, when primary is down it will collect request while nodes are voting.
  # Importaint to say, that requests will be stored in this object only for `timeout` period.
  class EMProxyConnection
    # Pause while searching server in seconds
    WAIT = 0.1
    
    def initialize(client)
      @client = client
      @timeout = @client.timeout
      @requests = []
    end

    # If timeout is defined then collect request and start timout.
    # If timout is not defined or zero then return exception.
    def send_command(msg, request_id = nil, &cb)
      if @timeout && @timeout > 0 
        @requests << [msg, request_id, cb]
        set_timeout
        find_server!
      else
        error = Monga::Exceptions::ServerDisconnected, "Can't find appropriate server (all disconnected)"
        cb.call(error)
      end
    end

    # If timout happend send exception to all collected requests.
    def set_timeout
      unless @pending_timout
        @pending_timout = true
        EM.add_timer(@timout) do
          @requests.each do |msg, rid, cb|
            error = Monga::Exceptions::ServerDisconnected, "Can't find appropriate server (all disconnected)"
            cb.call(error)
          end
          @requests.clear
          @pending_timout = false
        end
      end
    end

    # Find server unless server is found
    def find_server!
      unless @pending_server
        @pending_server = true
        @clients.each do |client|
          client.force_status! do |status|
            case status
            when :primary
              if [:primary, :primary_preferred, :secondary_preferred].inclue? @read_pref
                @pending_server = false
                server_found!
              end
            when :secondary
              if [:secondary, :primary_preferred, :secondary_preferred].inclue? @read_pref
                @pending_server = false
                server_found!
              end
            when nil
              @pending_server = false
              EM.add_timer(WAIT) do
                EM.next_tick{ find_server! }
              end
            end
          end
        end
      end

      # YEEEHA! Send all collected requests back to client
      def server_found!
        @requests.each do |req|
          @client.aquire_connection.send_command(*req)
        end
        @requests.clear
      end
    end
  end
end