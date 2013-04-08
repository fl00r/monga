module Monga
  class Response
    def wait
      fib = Fiber.current
      callback do |res|
        fib.resume(res)
      end
      errback do |err|
        fib.resume(err)
      end
      res = Fiber.yield
      raise res if Exception === res
      res
    end

    def self.surround
      resp = new
      yield(resp)
      resp.wait
    end
  end
end