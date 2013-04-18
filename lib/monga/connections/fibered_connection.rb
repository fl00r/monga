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
        @responses[request_id] = fib
        res = Fiber.yield
        raise res if Exception === res
        cb.call(res)
      end
    end
  end
end

Patching async iteration in sync mode!
module Monga
  class Cursor
    alias_method :orig_each_batch, :each_batch

    def each_batch(&blk)
      begin
        fib = Fiber.current
        new_blk = proc{ |err, batch, iter|
          fib.resume(err, batch, iter)
        }
        orig_each_batch(&new_blk)
        err, batch, iter = Fiber.yield
        raise err if err
        yield batch
      end while iter
    end
  end
end