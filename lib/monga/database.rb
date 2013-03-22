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

    def cmd(cmd, options={})
      Monga::Requests::Query.new(self, "$cmd", query: cmd, options: options).callback_perform
    end

    def get_last_error
      cmd(getLastError: 1)
    end

    def drop_collection(collection_name)
      cmd(drop: collection_name)
    end

    def create_collection(collection_name, opts = {})
      cmd({create: collection_name}.merge(opts))
    end

    def count(collection_name)
      response = Monga::Response.new
      req = cmd(count: collection_name)
      req.callback do |res|
        response.succeed(res["n"].to_i)
      end
      req.errback do |res|
        exception = Monga::Exceptions::QueryFailure.new(res)
        response.fail(exception)
      end
      response
    end

    # Just helper
    def list_collections
      response = Monga::Response.new
      req = cmd(eval: "db.getCollectionNames()")
      req.callback do |res|
        response.succeed(res["retval"])
      end
      req.errback do |res|
        exception = Monga::Exceptions::QueryFailure.new(res)
        response.fail(exception)
      end
      response
    end
  end
end