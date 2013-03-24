module Monga
  class Miner < EM::DefaultDeferrable
    def initialize(db, collection_name, options)
      @db = db
      @collection_name = collection_name
      @options = options

      # Defaults
      @options[:limit] = 0
      @options[:skip] = 0
      @options[:batch_size] = 0
    end

    def cursor(flags = {})
      @cursor ||= Monga::Cursor.new(@db, @collection_name, @options, flags)
    end

    def limit(count)
      @options[:limit] = count && self
    end

    def skip(count)
      @options[:skip] = count && self
    end

    def batch_size(count)
      @options[:batch_size] = count && self
    end

    # Lazy operation execution
    [:callback, :errback, :timeout].each do |meth|
      class_eval <<-EOS
        def #{meth}(*args)
          mine! && @defered = true unless @deferred
          super
        end
      EOS
    end

    private

    def mine!
      docs = []
      cursor.each_doc do |doc|
        docs << doc
      end
      cursor.callback do
        succeed docs
      end
      cursor.errback do |err|
        fail err
      end
    end
  end
end