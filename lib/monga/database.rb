module Monga
  class Database
    attr_reader :client, :name

    def initialize(client, name)
      @client = client
      @name = name
    end

    def get_collection(collection_name)
      Monga::Collection.new(self, collection_name)
    end
    alias :[] :get_collection

    def cmd(cmd, opts={})
      run_cmd(cmd, opts) do |err, resp|
        if block_given?
          yield(err, resp)
        else
          err ? raise(err) : resp
        end
      end
    end

    def get_last_error(connection)
      run_cmd({getLastError: 1}, {connection: connection}) do |err, resp|
        err, resp = check_response(err, resp)
        if block_given? 
          yield(err, resp)
        else
          err ? raise(err) : resp
        end
      end
    end

    def drop_collection(collection_name)
      run_cmd(drop: collection_name) do |err, resp|
        err, resp = check_response(err, resp)
        if block_given? 
          yield(err, resp)
        else
          err ? raise(err) : resp
        end
      end
    end

    def create_collection(collection_name, opts = {})
      with_response do
        run_cmd({create: collection_name}.merge(opts))
      end
    end

    def count(collection_name)
      run_cmd(count: collection_name) do |err, resp|
        if err
          block_given? ? yield(err, resp) : raise(err)
        else
          cnt = resp["n"].to_i
          block_given? ? yield(err, cnt) : cnt
        end
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
      run_cmd(eval: js) do |err, resp|
        yield(err, resp)
      end
    end

    def run_cmd(cmd, opts = {})
      connection = opts.delete :connection
      connection ||= @client.aquire_connection

      options = {}
      options[:query] = cmd
      options.merge! opts

      Monga::Cursor.new(connection, name, "$cmd", options).first do |err, resp|
        yield(err, resp)
      end
    end

    def check_response(err, data)
      if err
        [err, data]
      elsif data.nil? || data.empty?
        error = Monga::Exceptions::QueryFailure.new("Empty Response is not a valid Response")
        [error, data]
      else
        [nil, data]
      end
    end
  end
end