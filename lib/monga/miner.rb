# Miner is a "proxy" object to Cursor.
# It dinamically stores Cursor options and at any moment can return cursor.
# Also it hides Deferrable that could return all objects that cursor do.
module Monga
  class Miner < EM::DefaultDeferrable
    attr_reader :options
    
    def initialize(db, collection_name, options={})
      @db = db
      @collection_name = collection_name
      @options = options

      # Defaults
      @options[:query] ||= {}
      @options[:limit] ||= 0
      @options[:skip] ||= 0
    end

    def cursor(flags = {})
      @cursor = Monga::Cursor.new(@db, @collection_name, @options, flags)
    end

    def limit(count)
      @options[:limit] = count and self
    end

    def skip(count)
      @options[:skip] = count and self
    end

    def batch_size(count)
      @options[:batch_size] = count and self
    end

    # Lazy operation execution
    [:callback, :errback, :timeout].each do |meth|
      class_eval <<-EOS
        def #{meth}(*args)
          mine! && @deferred = true unless @deferred
          super
        end
      EOS
    end

    private

    def mine!
      docs = []
      itrator = cursor.each_doc do |doc|
        docs << doc
      end
      itrator.callback do |resp|
        succeed docs
      end
      itrator.errback do |err|
        fail err
      end
    end
  end
end