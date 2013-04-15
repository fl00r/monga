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
  end

  class Collection
    # All API methods which returns Deferrable
    RESPONSE_METHODS = %w{ find_one first safe_insert safe_update safe_delete safe_remove ensure_index drop_index drop_indexes get_indexes drop count }

    RESPONSE_METHODS.each do |m|
      alias :"old_#{m}" :"#{m}"
      class_eval <<-EOS
        def #{m}(*args)
          old_#{m}(*args).wait
        end
      EOS
    end

    %w{ find query }.each do |m|
      alias :"old_#{m}" :"#{m}"
      class_eval <<-EOS
        def #{m}(*args)
          old_#{m}(*args).to_a.wait
        end
      EOS
    end
  end
end