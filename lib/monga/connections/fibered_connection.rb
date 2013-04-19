require 'fiber'

class Fiber
  alias :call :resume
end

module Monga::Connections
  class FiberedConnection < EMConnection
    def send_command(msg, request_id=nil, &cb)
      fib = Fiber.current
      reconnect unless @connected

      callback do
        send_data msg
      end

      if cb
        reconnect unless @connected
        @responses[request_id] = fib
        res = Fiber.yield
        raise res if Exception === res
        cb.call(res)
      end
    end
  end
end