module Monga
  class Miner
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

    def explain
      @options[:explain] = true
    end

    def hint
      @options[:hint] = true
    end

    def sort(val)
      @options[:sort] = val
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

    def to_a
      Monga::Response.surround do |response|
        docs = []
        itrator = cursor.each_doc do |doc|
          docs << doc
        end
        itrator.callback do |resp|
          response.succeed docs
        end
        itrator.errback do |err|
          response.fail err
        end
      end
    end
    alias :all :to_a
  end
end