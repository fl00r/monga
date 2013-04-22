module Monga::Connections
  class FiberedProxyConnection < EMProxyConnection
    def send_command(msg, request_id = nil, &cb)
      if @timeout && @timeout > 0
        @requests[request_id] = [msg, @fib]
        @fib = Fiber.current
        set_timeout
        find_server!
        res = Fiber.yield
        @requests.delete(request_id)
        raise res if Exception === res
        @client.aquire_connection.send_command(msg, request_id, &cb)
      else
        error = Monga::Exceptions::Disconnected.new "Can't find appropriate server (all disconnected)"
        cb.call(error) if cb
      end
    end

    def server_found!
      @fib.resume
    end
  end
end