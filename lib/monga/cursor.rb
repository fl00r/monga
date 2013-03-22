module Monga
  class Cursor
    def initialize(options, select_options)
      @options = options
      @select_options = select_options
      @limit = 1
      @skip = 0
    end

    def limit(count)
      @limit = count
      self
    end

    def skip(count)
      @skip = count
      self
    end

    def get_more(&blk)
      find do |resp|
        blk.call(resp)
        @skip += limit
        get_more(blk)
      end
    end

    def find
      request = Monga::Requests::Query.new()
      request.perform
    end
  end
end