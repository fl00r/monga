module Monga
  class Cursor < EM::DefaultDeferrable
    def initialize(options, select_options)
      @options = options
      @select_options = select_options
      @limit = 1
      @skip = 0

      @deferred = false
    end

    def limit(count)
      @limit = count
      self
    end

    def skip(count)
      @skip = count
      self
    end

    def each_doc(blk)
      
    end

    def callback(&blk)
      unless @deferred
        case @type
        when "cursor"
          find_each.callback_perform
        when "all"
          find_all.callback_perform
        end
        @deferred = true
      end
      super
    end
    alias :errback :callback
    alias :timeout :callback

    private

    def find_all

    end

    def find_each
      
    end
  end
end