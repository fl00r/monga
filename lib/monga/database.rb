module Monga
  class Database
    attr_reader :client, :name

    def initialize(client, name)
      @client = client
      @name = name
    end

    def [](collection_name)
      Monga::Collection.new(self, collection_name)
    end

    def cmd(cmd, opts={})
      run_cmd(cmd, opts)
    end

    def eval(js)
      run_eval(eval: js)
    end

    # Be carefull with using get_last_error with connection pool.
    # In most cases you need to use #safe methods 
    # and don't access to #get_last_error directky
    def get_last_error
      with_response do
        run_cmd(getLastError: 1)
      end
    end

    def drop_collection(collection_name)
      with_response do
        run_cmd(drop: collection_name)
      end
    end

    def create_collection(collection_name, opts = {})
      with_response do
        run_cmd({create: collection_name}.merge(opts))
      end
    end

    def count(collection_name)
      Monga::Response.surround do |resp|
        req = with_response do
          run_cmd(count: collection_name)
        end
        req.callback do |data|
          cnt = data.first["n"].to_i
          resp.succeed cnt
        end
        req.errback{ |err| resp.fail err }
      end
    end

    def drop_indexes(collection_name, indexes)
      with_response do
        run_cmd(dropIndexes: collection_name, index: indexes)
      end
    end

    # Just helper
    def list_collections
      Monga::Response.surround do |resp|
        req = run_eval("db.getCollectionNames()")
        req.callback do |data|
          resp.succeed(data.first["retval"])
        end
        req.errback do |err|
          resp.fail(err)
        end
      end
    end

    private

    def run_eval(js)
      with_response do
        run_cmd(eval: js)
      end
    end

    def run_cmd(cmd, opts={})
      options = {}
      options[:query] = cmd
      options.merge! opts
      Monga::Miner.new(self, "$cmd", options).limit(1).all
    end

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