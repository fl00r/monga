module Monga
  class Cursor
    attr_reader :cursor_id

    CURSORS = {}
    CLOSED_CURSOR = 0
    # Batch kill cursors marked to be killed each CLOSE_TIMEOUT seconds
    CLOSE_TIMEOUT = 1

    def initialize(client, db_name, collection_name, options = {}, flags = {})
      @client = client
      @db_name = db_name
      @collection_name = collection_name
      @connection = options.delete :connection
      @options = options
      # WTF??!
      @options.merge!(flags)

      @fetched_docs = []
      @count = 0

      @options[:limit] ||= 0
    end

    def flag(opt)
      @options.merge!(opt) and self
    end

    def limit(val)
      @options[:limit] = val and self
    end

    def skip(val)
      @options[:skip] = val and self
    end

    def batch_size(val)
      @options[:batch_size] = val and self
    end

    def explain
      @options[:explain] = true and self
    end

    def hint
      @options[:hint] = true and self
    end

    def sort(val)
      @options[:sort] = val and self
    end

    def kill
      return if @cursor_id == CLOSED_CURSOR
      self.class.kill_cursors(@connection, @cursor_id)
      CURSORS.delete @cursor_id
      @cursor_id = 0
    end

    def self.batch_kill(conn)
      cursors = CURSORS.select{ |k,v| v }
      cursor_ids = cursors.keys
      if cursor_ids.any?
        Monga.logger.debug("Following cursors are going to be deleted: #{cursor_ids}")
        kill_cursors(conn, cursor_ids)
        cursor_ids.each{ |id| CURSORS.delete id }
      end
    end

    # Sometime in future all marked cursors will be killed in batch
    def mark_to_kill
      CURSORS[@cursor_id] = true if @cursor_id && alive?
      @cursor_id = 0
    end

    private

    def get_more(batch_size, &block)
      blk = proc do |err, data|
        if err
          mark_to_kill
          block.call(err)
        else
          @cursor_id = data[5]
          fetched_docs = data.last
          @count += fetched_docs.count
          mark_to_kill unless more?
          block.call(nil, fetched_docs, more?)
        end
      end
      if @cursor_id
        if @cursor_id == CLOSED_CURSOR
          err = Monga::Exceptions::ClosedCursor.new "You are trying to use closed cursor"
          block.call(err)
        else
          opts = @options.merge(cursor_id: @cursor_id, batch_size: batch_size)
          aquire_connection do |connection|
            Monga::Protocol::GetMore.new(connection, @db_name, @collection_name, opts).callback_perform(&blk)
          end
        end
      else
        aquire_connection do |connection|
          Monga::Protocol::Query.new(connection, @db_name, @collection_name, @options).callback_perform do |err, resp|
            blk.call(err, resp)
          end
        end
      end
    end

    def aquire_connection
      if @connection
        yield @connection
      else
        @client.aquire_connection do |connection|
          @connection = connection
          yield connection
        end
      end
    end

    def more?
      alive? && !satisfied?
    end

    # If cursor_id is not setted, or if isn't CLOSED_CURSOR - cursor is alive
    def alive?
      @cursor_id != CLOSED_CURSOR
    end

    # If global limit is setted 
    # we will be satisfied when we will get limit amount of documents.
    # Otherwise we are not satisfied untill crsor is alive
    def satisfied?
      @options[:limit] > 0 && @count >= @options[:limit]
    end

    # How many docs should be returned
    def rest
      @options[:limit] - @count if @options[:limit] > 0
    end

    # Cursor will get exact amount of docs as user passed with `limit` opr
    def get_batch_size
      if @options[:limit] > 0 && @options[:batch_size]
        rest < @options[:batch_size] ? rest : @options[:batch_size]
      else @options[:batch_size]
        @options[:batch_size]
      end
    end

    def self.kill_cursors(connection, cursor_ids)
      Monga::Protocol::KillCursors.new(connection, cursor_ids: [*cursor_ids]).perform
    end
  end

  class CallbackCursor < Cursor
    def next_batch
      get_more(get_batch_size) do |err, batch, more|
        if block_given?
          yield(err, batch, more)
        else
          err ? raise(err) : [batch, more]
        end
      end
    end

    def each_batch(&blk)
      iter_more = true
      iterator = Proc.new do
        if iter_more
          next_batch do |err, batch, more|
            iter_more = more
            (more || batch || err) ? blk.call(err, batch, iterator) : blk.call
          end
        else
          # iteration stopped
          blk.call
        end
      end
      class << iterator
        alias :next :call
      end
      iterator.next
    end

    def next_doc
      if doc = @fetched_docs.shift
        block_given? ? yield(nil, doc, more?) : [doc, more?]
      else
        get_more(get_batch_size) do |err, batch, more|
          if err
            block_given? ? yield(err, nil, false) : raise(err)
          else
            @fetched_docs = batch
            doc = @fetched_docs.shift
            m = more || @fetched_docs.any?
            block_given? ? yield(err, doc, m) : [doc, m]
          end
        end
      end
    end
    alias :next_document :next_doc

    def each_doc(&blk)
      iter_more = true
      iterator = Proc.new do
        if iter_more
          next_doc do |err, doc, more|
            iter_more = more
            (more || doc || err) ? blk.call(err, doc, iterator) : blk.call
          end
        else
          # iteration stopped
          blk.call
        end
      end
      class << iterator
        alias :next :call
      end
      iterator.next
    end
    alias :each_document :each_doc

    def all
      documents = []
      each_batch do |err, batch, iter|
        if err
          block_given? ? yield(err) : raise(err)
        else
          if iter
            documents += batch
            iter.next
          else
            block_given? ? yield(nil, documents) : documents
          end
        end
      end
    end

    def first
      limit(1).all do |err, resp|
        if err
          block_given? ? yield(err) : raise(err)
        else
          block_given? ? yield(nil, resp.first) : resp.first
        end
      end
    end
  end

  class BlockCursor < Cursor
    def next_batch
      get_more(get_batch_size) do |err, batch, more|
        raise(err) if err
        return [batch, more]
      end
    end

    def each_batch
      begin
        batch, more = next_batch
        yield batch if more || batch
      end while more
    end

    def next_doc
      if doc = @fetched_docs.shift
        [doc, more?]
      else
        batch, more = next_batch
        @fetched_docs = batch
        doc = @fetched_docs.shift
        m = more || @fetched_docs.any?
        return [doc, m]
      end
    end
    alias :next_document :next_doc

    def each_doc
      begin
        doc, more = next_doc
        yield doc if more || doc
      end while more
    end
    alias :each_document :each_doc

    def all
      documents = []
      each_batch do |batch|
        documents += batch
      end
      documents
    end

    def first
      resp = limit(1).all
      resp.first
    end
  end
end