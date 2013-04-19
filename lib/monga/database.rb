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

    def cmd(cmd, opts = {}, resp_blk = nil, &ret_blk)
      run_cmd(cmd, opts, ret_blk, resp_blk)
    end

    def eval(js, &blk)
      run_eval(cmd, blk)
    end

    def get_last_error(connection, &blk)
      run_cmd({ getLastError: 1 }, { connection: connection }, blk)
    end

    def drop_collection(collection_name, &blk)
      run_cmd({ drop: collection_name }, {}, blk)
    end

    def create_collection(collection_name, opts = {}, &blk)
      cmd = {}
      cmd[:create] = collection_name
      cmd.merge!(opts)
      run_cmd(cmd, {}, blk)
    end

    def count(collection_name, opts = {}, &blk)
      cmd = {}
      cmd[:count] = collection_name
      cmd.merge!(opts)
      run_cmd(cmd, {}, blk) do |resp|
        resp["n"].to_i
      end
    end

    def drop_indexes(collection_name, indexes, &blk)
      cmd = {}
      cmd[:dropIndexes] = collection_name
      cmd[:index] = indexes
      run_cmd(cmd, {}, blk)
    end

    # Just helper
    def list_collections(&blk)
      run_eval("db.getCollectionNames()", blk)
    end

    private

    def run_eval(js, blk)
      cmd = {}
      cmd[:eval] = js
      run_cmd(cmd, {}, blk)
    end

    def run_cmd(cmd, opts, ret_blk, &resp_blk)
      connection = opts.delete :connection
      connection ||= @client.aquire_connection

      options = {}
      options[:query] = cmd
      options.merge! opts

      Monga::CallbackCursor.new(connection, name, "$cmd", options).first do |err, resp|
        make_response(err, resp, ret_blk, resp_blk)
      end
    end

    def make_response(err, resp, ret_blk, resp_blk)
      err, resp = check_response(err, resp)
      if err
        if ret_blk
          ret_blk.call(err, resp)
        else
          raise err
        end
      else
        resp = resp_blk.call(resp) if resp_blk
        if ret_blk
          ret_blk.call(err, resp)
        else
          return resp
        end
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