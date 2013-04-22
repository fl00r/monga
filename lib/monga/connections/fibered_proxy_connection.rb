module Monga::Connections
  class FiberedProxyConnection < EMProxyConnection
    def send_command(msg, request_id = nil, &cb)
      if @timeout && @timeout > 0
        @requests << [msg, request_id, @fib]
        @fib = Fiber.current
        set_timeout
        find_server!
        res = Fiber.yield
        @requests.clear
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