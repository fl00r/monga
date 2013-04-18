module EM
  module Deferrable
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
end

module Monga

  class Collection
    # All API methods which returns Deferrable
    RESPONSE_METHODS = %w{ find_one first safe_insert safe_update safe_delete safe_remove ensure_index drop_index drop_indexes drop count }

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
          old_#{m}(*args).to_a
        end
      EOS
    end
  end

  class Database
    RESPONSE_METHODS = %w{ cmd eval get_last_error drop_collection create_collection count drop_indexes list_collections }

    RESPONSE_METHODS.each do |m|
      alias :"old_#{m}" :"#{m}"
      class_eval <<-EOS
        def #{m}(*args)
          old_#{m}(*args).wait
        end
      EOS
    end
  end

  class Miner
    def to_a
      docs = []
      cursor.each_doc do |doc|
        docs << doc
      end
      docs
    end
    alias :all :to_a
  end

  class Cursor
    RESPONSE_METHODS = %w{ next_document }

    RESPONSE_METHODS.each do |m|
      alias :"old_#{m}" :"#{m}"
      class_eval <<-EOS
        def #{m}(*args, &blk)
          old_#{m}(*args).wait
        end
      EOS
    end
  end
end