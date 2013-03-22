module Monga
  class Collection
    attr_reader :connection, :name

    def initialize(db, name)
      @db = db
      @connection = @db.connection
      @name = name
    end

    # db_name.collectio_name
    def full_name
      [@db.name, @name] * "."
    end

    def query(query = {}, fields = {}, opts = {})
      Monga::Cursor.new(self, query, fields, opts)
    end
    alias :find :query

    def find_one(query = {}, fields = {}, opts = {})
      Monga::Cursor.new(self, query, fields, opts).limit(1)
    end
    alias :first :find_one

    def insert(documents, opts = {}, safe = false)
      options = {}
      options[:documents] = documents
      options.merge!(opts)

      if safe
        Monga::Requests::Insert.new(self, options).safe_perform
      else
        Monga::Requests::Insert.new(self, options).perform
      end
    end

    def safe_insert(documents, opts = {})
      insert(documents, opts, true)
    end

    def update(query = {}, update = {}, flags = {})
      options = {}
      options[:query] = query
      options[:update] = update
      options[:flags] = flags
      Monga::Requests::Update.new(self, options).perform
    end

    def delete(query = {}, opts = {}, safe = false)
      options = {}
      options[:query] = query
      options.merge!(opts)
      Monga::Requests::Delete.new(self, options).perform
    end
    alias :remove :delete

    def ensureIndex
      # TODO
    end
  end
end