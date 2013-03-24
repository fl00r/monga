module Monga
  class Collection
    attr_reader :connection, :name, :db

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
      Monga::Requests::Query.new(@db, "system.indexes", options).perform
    end

    def ensure_index_version(key, opts={})
      if version = opts[:v]
        response = Monga::Response.new
        req = get_indexes
        req.errback do |err|
          response.fail(err)
        end
        req.callback do |res|
          response.succeed(res)
        end
        response
      else
        raise Monga::Exceptions::UndefinedIndexVersion, "you should pass `v` argument as a version to ensure index version, or use simple ensure_index method"
      end
    end

    def drop_indexes
      @db.drop_indexes
    end

    def get_indexes
      Monga::Requests::Query.new(@db, "system.indexes", {limit: -5}).callback_perform
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
      req.callback do |data|
        response.succeed(request_id)
      end
      req.errback{ |err| response.fail(err) }
      response
    end
  end
end