module Monga
  class Collection
    attr_reader :collection_name

    def initialize(db, collection_name)
      @db = db
      @collection_name = collection_name
    end

    def query(query = {}, selector = {}, opts = {})
      options = {}
      options[:query] = query
      options[:selector] = selector
      options.merge!(opts)
      Monga::Cursor.new(connection, db_name, collection_name, options)
    end
    alias :find :query

    def find_one(query = {}, selector = {}, opts = {})
      options = {}
      options[:query] = query
      options[:selector] = selector
      options.merge!(opts)
      Monga::Cursor.new(connection, db_name, collection_name, options).limit(1)
    end
    alias :first :find_one

    def insert(document, opts = {})
      options = {}
      options[:documents] = document
      options.merge!(opts)
      Monga::Protocol::Insert.new(connection, db_name, collection_name, options).perform
    end

    def update(query = {}, update = {}, flags = {})
      options = {}
      options[:query] = query
      options[:update] = update
      options.merge!(flags)
      Monga::Protocol::Update.new(connection, db_name, collection_name, options).perform
    end

    def delete(query = {}, opts = {})
      options = {}
      options[:query] = query
      options.merge!(opts)
      Monga::Protocol::Delete.new(connection, db_name, collection_name, options).perform
    end
    alias :remove :delete

    def ensure_index(keys, opts={})
      doc = {}
      doc.merge!(opts)
      # Read docs about naming
      doc[:name] ||= keys.to_a.flatten * "_"
      doc[:key] = keys
      doc[:ns] = "#{db.name}.#{name}"
      Monga::Protocol::Insert.new(connection, db_name, "system.indexes", {documents: doc}).perform
    end

    def drop_index(indexes)
      @db.drop_indexes(@name, indexes)
    end

    def drop_indexes
      @db.drop_indexes(@name, "*")
    end

    def get_indexes
      Monga::Miner.new(@db, "system.indexes").all
    end

    def drop
      @db.drop_collection(@name)
    end

    def count
      @db.count(@collection_name) do |err, res|
        if block_given?
          yield(err, res)
        else
          err ? raise(err) : res
        end
      end
    end

    # Safe methods
    [:update, :insert, :delete, :remove, :ensure_index].each do |meth|
      class_eval <<-EOS
        def safe_#{meth}(*args)
          req = #{meth}(*args)
          @db.get_last_error(req.connection) do |err, resp|
            if block_given?
              yield(err, resp)
            else
              err ? raise(err) : resp
            end
          end
        end
      EOS
    end

    private

    def connection
      @db.client.aquire_connection
    end

    def db_name
      @db.name
    end
  end
end