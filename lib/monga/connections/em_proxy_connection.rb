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
        error = Monga::Exceptions::Disconnected.new "Can't find appropriate server (all disconnected)"
        cb.call(error) if cb
      end
    end

    # If timeout happend send exception to all collected requests.
    def set_timeout
      unless @pending_timeout
        @pending_timeout = true
        EM.add_timer(@timeout) do
          @requests.each do |msg, rid, cb|
            error = Monga::Exceptions::Disconnected.new "Can't find appropriate server (all disconnected)"
            cb.call(error)
          end
          @requests.clear
          @pending_timeout = false
        end
      end
    end

    # Find server unless server is found
    def find_server!
      unless @pending_server
        @pending_server = true
        _count = 0
        @client.clients.each do |client|
          client.force_status! do |status|
            if status == :primary && [:primary, :primary_preferred, :secondary_preferred].include?(@client.read_pref)
              @pending_server = false
              server_found!
            elsif status == :secondary && [:secondary, :primary_preferred, :secondary_preferred].include?(@client.read_pref)
              @pending_server = false
              server_found!
            else
              EM.add_timer(WAIT) do
                EM.next_tick do
                  @pending_server = false if (_count +=1) == @client.clients.size
                  find_server!
                end
              end
            end
          end
        end
      end

      # YEEEHA! Send all collected requests back to client
      def server_found!
        @requests.each do |msg, request_id, blk|
          @client.aquire_connection.send_command(msg, request_id, &blk)
        end
        @requests.clear
      end
    end
  end
end