module Monga
  class Collection
    attr_reader :connection, :name

    def initialize(db, name)
      @db = db
      @connection = @db.connection
      @name = name
    end

    def query(query = {}, fields = {}, opts = {})
      Monga::Cursor.new(@name, query, fields, opts)
    end
    alias :find :query

    def find_one(query = {}, fields = {}, opts = {})
      Monga::Cursor.new(@name, query, fields, opts).limit(1)
    end
    alias :first :find_one

    def insert(documents, opts = {})
      options = {}
      options[:documents] = documents
      options.merge!(opts)
      Monga::Requests::Insert.new(@db, @name, options).perform
    end

    def update(query = {}, update = {}, flags = {})
      options = {}
      options[:query] = query
      options[:update] = update
      options[:flags] = flags
      Monga::Requests::Update.new(@db, @name, options).perform
    end

    def delete(query = {}, opts = {})
      options = {}
      options[:query] = query
      options.merge!(opts)
      Monga::Requests::Delete.new(@db, @name, options).perform
    end
    alias :remove :delete

    def ensure_index(keys, opts={})
      options = { query: keys, options: opts}
      Monga::Requests::Query(@db, "system.indexes", options).perform
    end

    def get_indexes
      options = { query: { getIndexes: 1 } }
      Monga::Requests::Query.new(@db, @name, options).callback_perform
    end

    def drop
      @db.drop_collection(@name)
    end

    def count
      @db.count(@name)
    end

    # Safe methods
    [:update, :insert, :delete].each do |meth|
      class_eval <<-EOS
        def safe_#{meth}(*args)
          safe do
            #{meth}(*args)
          end
        end
      EOS
    end

    def safe
      response = Monga::Response.new
      request_id = yield
      req = @db.get_last_error
      req.callback do |res|
        if res["err"]
          err = Monga::Exceptions::QueryFailure.new(res["err"])
          response.fail(err)
        else
          response.succeed(request_id)
        end
      end
      req.errback{ |err| resonse.fail(err) }
      response
    end
  end
end