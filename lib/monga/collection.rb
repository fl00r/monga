module Monga
  class Collection
    attr_reader :connection, :name

    def initialize(connection, name)
      @connection = connection
      @name = name
    end

    def query(query = {}, fields = {}, opts = {})
      Monga::Cursor.new(self, query, fields, opts)
    end
    alias :find :query

    def find_one(query = {}, fields = {}, opts = {})
      Monga::Cursor.new(self, query, fields, opts).limit(1)
    end
    alias :first :find_one

    def insert(documents, opts = {})
      options = {}
      options[:documents] = documents
      options[:options] = opts
      Monga::Requests::Insert.new(self, options).perform
    end

    def safe_insert(documents, opts = {})
      options = {}
      options[:documents] = documents
      options[:options] = opts
      Monga::Requests::Insert.new(self, options).safe_perform
    end

    def update(query = {}, update = {}, flags = {})
      options = {}
      options[:query] = query
      options[:update] = update
      options[:flags] = flags
      Monga::Requests::Update.new(self, options).perform
    end

    def delete(query, opts = {})
      Monga::Requests::Delete.new(self, query, opts).perform
    end

    def ensureIndex
      # TODO
    end
  end
end