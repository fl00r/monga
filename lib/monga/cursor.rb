module Monga
  class Cursor < EM::DefaultDeferrable
    def initialize(db, collection_name, options, flags)
      @db = db
      @collection_name = collection_name
      @options = options
      @flags = flags

      @fetched_docs = []
      @count = count
      @limit = @options[:limit]
    end

    def each_doc
      req = next_document
      req.callback do |doc|
        if doc
          yield doc
        else
          succeed
        end
      end
      req.errback do |err|
        fail err
      end
    end

    def get_more
      if @cursor_id
        opts = {} # todo
        Monga::Requests::GetMore.new(@db, @collection_name, opts).callback_perform
      else
        Monga::Requests::Query.new(@db, @collection_name, @options).callback_perform
      end
    end

    def next_document
      @count += 1
      Monga::Response.surround do |resp|
        if @count > @limit
          resp.succeed(nil)
        elsif doc = @fetched_docs.shift
          resp.succeed(doc)
        else
          req = get_more
          req.callback do |docs|
            @fetched_docs = docs
            resp.succeed(@fetched_docs.shift)
          end
          req.errback do |err|
            resp.fail err
          end
        end
      end
    end
  end
end