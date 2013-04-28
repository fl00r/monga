module Monga::Connections
  class FiberedProxyConnection < EMProxyConnection

    def type
      :sync
    end
    
    def send_command(msg, request_id = nil, &cb)
      if @timeout && @timeout > 0
        @fib = Fiber.current
        @requests[request_id] = [msg, @fib]
        set_timeout
        find_server!
        res = Fiber.yield
        raise res if Exception === res
        conn = @client.aquire_connection
        conn.send_command(msg, request_id, &cb)
      else
        error = Monga::Exceptions::Disconnected.new "Can't find appropriate server (all disconnected)"
        cb.call(error) if cb
      end
    end

    def server_found!
      @pending_server = false
      @pending_timeout.cancel if @pending_timeout
      @pending_timeout = nil
      @requests.keys.each do |req_id|
        msg, fib = @requests.delete req_id
        fib.call
      end
    end
  end
end