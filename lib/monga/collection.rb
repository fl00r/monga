module Monga
  class Collection
    attr_reader :collection_name, :db

    def initialize(db, collection_name)
      @db = db
      @collection_name = collection_name
    end

    def query(query = {}, selector = {}, opts = {})
      options = {}
      options[:query] = query
      options[:selector] = selector
      options.merge!(opts)
      Monga::CallbackCursor.new(request_opts, options)
    end
    alias :find :query

    def find_one(query = {}, selector = {}, opts = {}, &blk)
      query(query, selector, opts).first(&blk)
    end
    alias :first :find_one

    def insert(document, opts = {}, &blk)
      options = {}
      options[:documents] = document
      options.merge!(opts)
      Monga::Protocol::Insert.new(request_opts, options).perform(&blk)
    end

    def update(query = {}, update = {}, flags = {}, &blk)
      options = {}
      options[:query] = query
      options[:update] = update
      options.merge!(flags)
      Monga::Protocol::Update.new(request_opts, options).perform(&blk)
    end

    def delete(query = {}, opts = {}, &blk)
      options = {}
      options[:query] = query
      options.merge!(opts)
      Monga::Protocol::Delete.new(request_opts, options).perform(&blk)
    end
    alias :remove :delete

    def ensure_index(keys, opts={}, &blk)
      doc = {}
      doc[:key] = keys
      doc[:name] ||= keys.to_a.flatten * "_"
      doc[:ns] = "#{@db.name}.#{@collection_name}"
      doc.merge!(opts)
      Monga::Protocol::Insert.new(index_request_opts, {documents: doc}).perform(&blk)
    end

    def drop_index(indexes, &blk)
      @db.drop_indexes(@collection_name, indexes, &blk)
    end

    def drop_indexes(&blk)
      @db.drop_indexes(@collection_name, "*", &blk)
    end

    def get_indexes(&blk)
      Monga::CallbackCursor.new(index_request_opts).all(&blk)
    end

    def drop(&blk)
      @db.drop_collection(@collection_name, &blk)
    end

    # You could pass query/limit/skip options
    #
    #    count(query: {artist: "Madonna"}, limit: 10, skip: 0)
    #
    def count(opts = {}, &blk)
      @db.count(@collection_name, opts, &blk)
    end

    def map_reduce(opts, &blk)
      @db.map_reduce(@collection_name, opts, &blk)
    end

    def aggregate(pipeline, &blk)
      @db.aggregate(@collection_name, pipeline, &blk)
    end

    def distinct(opts, &blk)
      @db.distinct(collection_name, opts, &blk)
    end

    def group(opts, &blk)
      @db.group(collection_name, opts, &blk)
    end

    def text(search, opts = {}, &blk)
      opts[:search] = search
      @db.text(collection_name, opts, &blk)
    end

    # Safe methods
    [:update, :insert, :delete, :remove, :ensure_index].each do |meth|
      class_eval <<-EOS
        def safe_#{meth}(*args, &blk)
          last = args.last
          opts = {}
          if Hash === last
            [ :j, :w, :fsync, :wtimeout ].each do |k|
              v = last.delete k
              opts[k] = v if v != nil
            end
          end
          #{meth}(*args) do |req|
            @db.raise_last_error(req.connection, opts, &blk)
          end
        end
      EOS
    end

    private

    def request_opts
      @request_opts ||= {
        client: @db.client,
        db_name: @db.name,
        collection_name: @collection_name
      }.freeze
    end

    def index_request_opts
      @index_request_opts ||= {
        client: @db.client,
        db_name: @db.name,
        collection_name: "system.indexes"
      }.freeze
    end
  end
end