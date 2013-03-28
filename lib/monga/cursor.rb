module Monga
  class Cursor < EM::DefaultDeferrable
    attr_reader :cursor_id

    CURSORS = {}
    CLOSED_CURSOR = 0
    # Batch kill cursors marked to be killed each CLOSE_TIMEOUT seconds
    CLOSE_TIMEOUT = 1

    EM.schedule do
      EM.add_periodic_timer(CLOSE_TIMEOUT){ batch_kill }
    end

    def initialize(db, collection_name, options = {}, flags = {})
      @keep_alive = true if flags.delete :keep_alive

      @db = db
      @collection_name = collection_name
      @options = options
      @options.merge!(flags)

      @fetched_docs = []
      @count = 0
      @total_count = 0
      @limit = @options[:limit] ||= 0
      @batch_size = @options[:batch_size]
    end

    def next_document
      Monga::Response.surround do |resp|
        if doc = @fetched_docs.shift
          resp.succeed doc
        else
          req = next_batch
          req.callback do |docs|
            @fetched_docs = docs
            if doc = @fetched_docs.shift
              @count =+ 1
              resp.succeed doc
            end
          end
          req.errback{ |err| resp.fail err }
        end
      end
    end

    def each_doc(&blk)
      if more?
        req = next_batch
        req.callback do |batch|
          if batch.any?
            batch.each do |doc|
              @count += 1
              blk.call(doc)
            end
            each_doc(&blk)
          else
            succeed
          end
        end
        req.errback{ |err| fail err }
      else
        succeed
      end
      self
    end

    def kill
      return unless @cursor_id > 0
      kill_cursors(@cursor_id)
      CURSORS.delete @cursor_id
      @cursor_id = 0
    end

    def self.batch_kill
      cursors = CURSORS.select{ |k,v| v }
      if cursors.any?
        kill_cursors(cursors)
      end
    end

    # Sometime in future all marked cursors will be killed in batch
    def mark_to_kill
      CURSORS[@cursor_id] = true if alive?
      @cursor_id = 0
    end

    # Cursor is alive and we need more minerals
    def more?
      alive? && !satisfied?
    end

    private

    def get_more(batch_size)
      Monga::Response.surround do |resp|
        req = if @cursor_id
          opts = { cursor_id: @cursor_id, batch_size: batch_size }
          Monga::Requests::GetMore.new(@db, @collection_name, opts).callback_perform
        else
          Monga::Requests::Query.new(@db, @collection_name, @options).callback_perform
        end
        req.callback do |data|
          @cursor_id = data[5]
          fetched_docs = data.last
          @total_count += fetched_docs.count
          mark_to_kill unless cursor_more?

          resp.succeed fetched_docs
        end
        req.errback do |err|
          mark_to_kill
          resp.fail err
        end
      end
    end

    def next_batch
      Monga::Response.surround do |resp|
        if more?
          batch_size = get_batch_size
          req = get_more(batch_size)
          req.callback{ |res| resp.succeed res }
          req.errback{ |err| resp.fail err }
        else
          mark_to_kill
          if !alive?
            resp.fail Monga::Exceptions::CursorIsClosed.new("Cursor is already closed. Check `cursor.more?` before calling cursor")
          elsif satisfied?
            resp.fail Monga::Exceptions::CursorLimit.new("You've already fetched #{@limit} docs you asked. Check `cursor.more?` before calling cursor")
          end
        end
      end
    end

    def cursor_more?
      alive? && !cursor_satisfied?
    end

    # If cursor_id is not setted, or if isn't CLOSED_CURSOR - cursor is alive
    def alive?
      @cursor_id != CLOSED_CURSOR
    end

    # If global limit is setted 
    # we will be satisfied when we will get limit amount of documents.
    # Otherwise we are not satisfied untill crsor is alive
    def satisfied?
      @limit > 0 && @count >= @limit
    end

    def cursor_satisfied?
      @limit > 0 && @total_count >= @limit
    end

    # How many docs should be returned
    def rest
      @limit - @count if @limit > 0
    end

    # Cursor will get exact amount of docs as user passed with `limit` opr
    def get_batch_size
      if @limit > 0 && @batch_size
        rest < @batch_size ? rest : @batch_size
      else @batch_size
        @batch_size
      end
    end

    def kill_cursors(cursor_ids)
      Monga::Requests::KillCursors.new(@db, @collection_name, cursor_ids: [*cursor_ids]).perform
    end

  end
end