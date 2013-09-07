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
      Monga::CallbackCursor.new(client, db_name, collection_name, options)
    end
    alias :find :query

    def find_one(query = {}, selector = {}, opts = {}, &blk)
      query(query, selector, opts).first(&blk)
    end
    alias :first :find_one

    def insert(document, opts = {}, &blk)
      safe = opts.delete :safe
      safe_opts = get_safe_opts(opts)  if safe
      options = {}
      options[:documents] = document
      options.merge!(opts)
      client.aquire_connection do |connection|
        Monga::Protocol::Insert.new(connection, db_name, collection_name, options).perform
        @db.get_last_error(connection, safe_opts, &blk)  if safe
      end
    end

    def safe_insert(document, opts = {}, &blk)
      opts[:safe] = true
      insert(document, opts, &blk)
    end

    def update(query = {}, update = {}, flags = {}, &blk)
      safe = flags.delete :safe
      safe_opts = get_safe_opts(flags)  if safe
      options = {}
      options[:query] = query
      options[:update] = update
      options.merge!(flags)
      client.aquire_connection do |connection|
        Monga::Protocol::Update.new(connection, db_name, collection_name, options).perform
        @db.get_last_error(connection, safe_opts, &blk)  if safe
      end
    end

    def safe_update(query = {}, update = {}, flags = {}, &blk)
      flags[:safe] = true
      update(query, update, flags, &blk)
    end

    def delete(query = {}, opts = {}, &blk)
      safe = opts.delete :safe
      safe_opts = get_safe_opts(opts)  if safe
      options = {}
      options[:query] = query
      options.merge!(opts)
      client.aquire_connection do |connection|
        Monga::Protocol::Delete.new(connection, db_name, collection_name, options).perform
        @db.get_last_error(connection, safe_opts, &blk)  if safe
      end
    end
    alias :remove :delete

    def safe_delete(query = {}, opts = {}, &blk)
      opts[:safe] = true
      delete(query, opts, &blk)
    end
    alias :safe_remove :safe_delete

    def ensure_index(keys, opts = {}, &blk)
      safe = opts.delete :safe
      safe_opts = get_safe_opts(opts)  if safe
      docs = { documents: {} }
      docs[:documents][:key] = keys
      docs[:documents][:name] ||= keys.to_a.flatten * "_"
      docs[:documents][:ns] = "#{@db.name}.#{@collection_name}"
      docs[:documents].merge!(opts)
      client.aquire_connection do |connection|
        Monga::Protocol::Insert.new(connection, db_name, "system.indexes", docs).perform
        @db.get_last_error(connection, safe_opts, &blk)  if safe
      end
    end

    def safe_ensure_index(keys, opts = {}, &blk)
      opts[:safe] = true
      ensure_index(keys, opts, &blk)
    end

    def drop_index(indexes, &blk)
      @db.drop_indexes(@collection_name, indexes, &blk)
    end

    def drop_indexes(&blk)
      @db.drop_indexes(@collection_name, "*", &blk)
    end

    def get_indexes(&blk)
      Monga::CallbackCursor.new(client, db_name, "system.indexes").all(&blk)
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

    private

    def client
      @client ||= @db.client
    end

    def db_name
      @db_name ||= @db.name
    end

    def get_safe_opts(opts)
      safe_opts = {}
      [ :j, :w, :fsync, :wtimeout ].each do |k|
        v = opts.delete k
        safe_opts[k] = v  unless v.nil?
      end
      safe_opts
    end
  end
end