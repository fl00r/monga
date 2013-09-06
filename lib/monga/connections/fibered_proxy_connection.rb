module Monga::Connections
  class FiberedProxyConnection < EMProxyConnection

    def type
      :sync
    end
    
    def send_command(msg, request_id = nil, &cb)
      if @found_connection && @found_connection.connected?
        @found_connection.send_command(msg, request_id, &cb)
      else
        @found_connection = nil
        if @timeout && @timeout > 0
          @fib = Fiber.current
          @requests[request_id] = [msg, @fib]
          set_timeout
          find_server!
          conn = Fiber.yield
          raise conn if Exception === conn
          conn.send_command(msg, request_id, &cb)
        else
          error = Monga::Exceptions::Disconnected.new "Can't find appropriate server (all disconnected)"
          cb.call(error) if cb
        end
      end
    end

    def server_found!
      @pending_server = false
      @pending_timeout.cancel if @pending_timeout
      @pending_timeout = nil
      @requests.keys.each do |req_id|
        msg, fib = @requests.delete req_id
        fib.call(@found_connection)
      end
    end
  end
end