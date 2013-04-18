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

# Patching async iteration in sync mode!
# module Monga
#   class Cursor
#     alias_method :orig_each_batch, :each_batch

#     def each_batch(&blk)
#       orig_each_batch do |err, batch, iter|
#         p [err, batch, iter]
#         # raise err if err
#         p batch
#         yield batch
#       end
#     end
#   end
# end