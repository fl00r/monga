module Monga
  class Database
    attr_reader :connection, :name

    def initialize(connection, name)
      @connection = connection
      @name = name
    end

    def [](collection_name)
      Monga::Collection.new(self, collection_name)
    end

    def cmd(cmd)
      Monga::Requests::Query.new(self, "$cmd", query: cmd).callback_perform
    end

    def get_last_error
      cmd(getLastError: 1)
    end

    def drop_collection(collection_name)
      cmd(drop: collection_name)
    end

    def create_collection(collection_name, opts = {})
      cmd(query: { create: collection_name }, options: opts)
    end

    # Just helper
    def list_collections
      cmd(eval: "db.getCollectionNames()")
    end
  end
end