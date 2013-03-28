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

    def cmd(cmd, opts={})
      options = {}
      options[:query] = cmd
      options.merge! opts
      Monga::Miner.new(self, "$cmd", options).limit(1)
    end

    def eval(js)
      with_response do
        cmd(eval: js)
      end
    end

    # Be carefull with using get_last_error with connection pool.
    # In most cases you need to use #safe methods 
    # and don't access to #get_last_error directky
    def get_last_error
      with_response do
        cmd(getLastError: 1)
      end
    end

    def drop_collection(collection_name)
      with_response do
        cmd(drop: collection_name)
      end
    end

    def create_collection(collection_name, opts = {})
      with_response do
        cmd({create: collection_name}.merge(opts))
      end
    end

    def count(collection_name)
      Monga::Response.surround do |resp|
        req = with_response do
          cmd(count: collection_name)
        end
        req.callback do |data|
          resp.succeed data.first["n"].to_i
        end
        req.errback{ |err| resp.fail err }
      end
    end

    def drop_indexes(collection_name, indexes)
      with_response do
        cmd(dropIndexes: collection_name, index: indexes)
      end
    end

    # Just helper
    def list_collections
      Monga::Response.surround do |resp|
        req = eval("db.getCollectionNames()")
        req.callback do |res|
          resp.succeed(res.first["retval"])
        end
        req.errback do |err|
          resp.fail(err)
        end
      end
    end

    private

    def with_response
      Monga::Response.surround do |resp|
        req = yield(resp)
        req.callback do |data|
          if data.any?
            resp.succeed(data)
          else
            exception = Monga::Exceptions::QueryFailure.new("Nothing was returned for your query: #{req.options[:query]}")
            resp.fail(exception)
          end
        end
        req.errback{ |err| resp.fail err }
      end
    end
  end
end