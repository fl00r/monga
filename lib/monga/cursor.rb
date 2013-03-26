module Monga
  class Cursor < EM::DefaultDeferrable
    def initialize(db, collection_name, options = {}, flags = {})
      @db = db
      @collection_name = collection_name
      @options = options
      @flags = flags

      @fetched_docs = []
      @count = 0
      @limit = @options[:limit] ||= 0
      @batch_size = @options[:batch_size]
    end

    def each_doc(&blk)
      req = next_batch
      req.callback do |docs|
        if docs
          docs.each do |doc|
            blk.call doc
          end
          @fetched_docs.clear
          each_doc(&blk)
        else
          succeed
        end
      end
      req.errback do |err|
        fail err
      end
      self
    end

    def get_more
      if @cursor_id
        batch_size = if @limit > 0
          rest = @limit - @count
          rest < @batch_size ? -rest : @batch_size
        else
          @batch_size
        end
        opts = { cursor_id: @cursor_id, batch_size: batch_size }
        Monga::Requests::GetMore.new(@db, @collection_name, opts).callback_perform
      else
        Monga::Requests::Query.new(@db, @collection_name, @options).callback_perform
      end
    end

    def next_batch
      Monga::Response.surround do |resp|
        if @limit > 0 && @count > @limit
          resp.succeed(nil)
        elsif (size = @fetched_docs.size) > 0
          if @limit > 0 && @count + size > @limit
            size = @limit - @count
            resp.succeed(@fetched_docs.take(size))
          else
            resp.succeed(@fetched_docs)
          end
          @count += size
        elsif @cursor_id == 0
          resp.succeed(nil)
        else
          req = get_more
          req.callback do |data|
            @cursor_id = data[5]
            @fetched_docs = data.last
            size = @fetched_docs.size
            if @limit > 0 && @count + size > @limit
              size = @limit - @count
              resp.succeed(@fetched_docs.take(size))
            else
              resp.succeed(@fetched_docs)
            end
            @count += size
          end
          req.errback do |err|
            resp.fail err
          end
        end
      end
    end

    def next_document
      Monga::Response.surround do |resp|
        if @limit > 0 && @count >= @limit
          resp.succeed(nil)
        elsif doc = @fetched_docs.shift
          resp.succeed(doc)
          @count += 1
        elsif @cursor_id == 0
          resp.succeed(nil)
        else
          req = get_more
          req.callback do |data|
            @cursor_id = data[5]
            @fetched_docs = data.last
            resp.succeed(@fetched_docs.shift)
            @count += 1
          end
          req.errback do |err|
            resp.fail err
          end
        end
      end
    end
  end
end