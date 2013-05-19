module Monga
  class Database
    attr_reader :client, :name

    def initialize(client, name)
      @client = client
      @name = name
    end

    # Choose collection to work
    #
    #   client = Monga:::Client.new
    #   db = client.get_db("dbTest")
    #   collection = db.get_collection("testCollection")
    #   # same as
    #   collection = db["testCollection"]
    #
    def get_collection(collection_name)
      Monga::Collection.new(self, collection_name)
    end
    alias :[] :get_collection

    # Run some command
    #
    #   cmd = { getLastError: 1 }
    #   db.cmd(cmd){ |err, resp| ... }
    #
    def cmd(cmd, resp_blk = nil, &ret_blk)
      if resp_blk
        run_cmd(cmd, ret_blk, &resp_blk)
      else
        run_cmd(cmd, ret_blk)
      end
    end

    # Evaluate some raw javascript
    #
    #   db.eval("return('Hello World!')") do |err, resp|
    #     # processing
    #   end
    #
    def eval(js, &blk)
      cmd = {}
      cmd[:eval] = js
      run_cmd(cmd, blk)
    end

    # You should be cearfull with this method 'cause it is importaint to know 
    # in wich connection you are trying to get last error information.
    # So be happy to use safe_* methods and it will choose right connection for you.
    # Or, if you really want to do it mannually:
    #
    #   request = collection.insert({ title: "Test" })
    #   conn = request.connection
    #   db.get_last_error(conn){ |err, resp| ... }
    #   db.get_last_error(conn){ |err, resp| ... }
    #   # you should pass following options:
    #   db.get_last_error(
    #     conn, 
    #     j: true, 
    #     w: 2, 
    #     fsync: true, 
    #     wtimout: 100){ |err, resp| ... }
    #
    def get_last_error(connection, opts = {}, &blk)
      raise_last_error(connection, opts, &blk)
    rescue => e
      return e
    end

    # Instead of get_last_eror this one will actually raise it.
    # It is usefull for safe_* methods who should raise an error if something goes wrong
    #
    def raise_last_error(connection, opts = {}, &blk)
      cmd = {}
      cmd[:getLastError] = 1
      cmd[:connection] = connection

      cmd[:j] = opts[:j] if opts[:j]
      cmd[:fsync] = opts[:fsync] if opts[:fsync]
      cmd[:w] = opts[:w] if opts[:w]
      cmd[:wtimeout] = opts[:wtimeout] if opts[:wtimeout]

      run_cmd(cmd, blk)
    end

    # Obviously dropping collection
    # There is collection#drop helper exists
    #
    #   db.drop_collection("testCollection"){ |err, resp| ... }
    #   # same as
    #   collection = db["testCollection"]
    #   collection.drop{ |err, resp| ... }
    #
    def drop_collection(collection_name, &blk)
      cmd = {}
      cmd[:drop] = collection_name
      run_cmd(cmd, blk)
    end

    # Create collection.
    #
    #   db.create_collection("myCollection"){ |err, resp| ... }
    #   db.create_collection("myCappedCollection", capped: true, size: 1024*10){ |err, resp| ... }
    #
    def create_collection(collection_name, opts = {}, &blk)
      cmd = {}
      cmd[:create] = collection_name
      cmd.merge!(opts)
      run_cmd(cmd, blk)
    end

    # Counts amount of documents in collection
    #
    #   db.count("myCollection"){ |err, cnt| ... }
    #   # same as
    #   collection = db["myCollection"]
    #   collection.count{ |err, cnt| ... }
    #
    def count(collection_name, opts = {}, &blk)
      cmd = {}
      cmd[:count] = collection_name
      cmd.merge!(opts)
      run_cmd(cmd, blk) do |resp|
        resp["n"].to_i
      end
    end

    # Drop choosen indexes.
    # There is collection#drop_index and collection#drop_indexes methods available
    # 
    #   db.drop_indexes("myCollection", { title: 1 })
    #   db.drop_indexes("myCollection", [{ title: 1 }, { author: 1 }])
    #   # drop all indexes
    #   db.drop_indexes("myCollection", "*")
    #   # same as
    #   collection = db["myCollection"]
    #   collection.drop_index(title: 1)
    #   # drop all indexes
    #   collection.drop_indexes
    #
    def drop_indexes(collection_name, indexes, &blk)
      cmd = {}
      cmd[:dropIndexes] = collection_name
      cmd[:index] = indexes
      run_cmd(cmd, blk)
    end

    # Run mapReduce command.
    # Available options:
    #   
    #   * map - A JavaScript function that associates or “maps” a value with a key and emits the key and value pair.
    #   * reduce - A JavaScript function that “reduces” to a single object all the values associated with a particular key.
    #   * out - Specifies the location of the result of the map-reduce operation.
    #   * query - Specifies the selection criteria.
    #   * sort - Sorts the input documents.
    #   * limit - Specifies a maximum number of documents to return from the collection
    #   * finalize
    #   * scope
    #   * jsMode
    #   * verbose
    # 
    # Inline response returned by default.
    #
    def map_reduce(collection_name, opts, &blk)
      cmd = {}
      cmd[:mapReduce] = collection_name
      cmd.merge! opts
      mcd[:out] ||= { inline: 1 }
      run_cmd(cmd, blk)
    end

    # Run aggregate command.
    # 
    def aggregate(collection_name, pipeline, &blk)
      cmd = {}
      cmd[:aggregate] = collection_name
      cmd[:pipeline] = pipeline
      run_cmd(cmd, blk)
    end

    # Run distinct command.
    # You should pass collection_name and key.
    # Query option is optional.
    # 
    def distinct(collection_name, opts, &blk)
      cmd = {}
      cmd[:distinct] = collection_name
      cmd.merge! opts
      run_cmd(cmd, blk)
    end

    # Run group command.
    # Available options are:
    #   key – Specifies one or more document fields to group
    #   $reduce – Specifies an aggregation function that operates on the documents during the grouping operation
    #   initial – Initializes the aggregation result document
    #   $keyf – Specifies a function that creates a “key object” for use as the grouping key
    #   cond – Specifies the selection criteria to determine which documents in the collection to process
    #   finalize – Specifies a function that runs each item in the result
    #
    def group(collection_name, opts, &blk)
      cmd = {}
      cmd[:group] = opts
      cmd[:group][:ns] ||= collection_name
      run_cmd(cmd, blk)
    end

    # Run text command.
    # Available options are:
    #   search (string) – A string of terms that MongoDB parses and uses to query the text index
    #   filter (document) – A query document to further limit the results of the query using another database field
    #   project (document) – Allows you to limit the fields returned by the query to only those specified.
    #   limit (number) – Specify the maximum number of documents to include in the response
    #   language (string) – Specify the language that determines for the search the list of stop words and the rules for the stemmer and tokenizer
    #   
    def text(collection_name, opts, &blk)
      cmd = {}
      cmd[:text] = collection_name
      cmd.merge! opts
      run_cmd(cmd, blk)
    end

    # Just helper to show all list of collections
    #
    #   db.list_collections{ |err, list| ... }
    #
    def list_collections(&blk)
      eval("db.getCollectionNames()", &blk)
    end

    private

    # Underlying command sending
    #
    def run_cmd(cmd, ret_blk, &resp_blk)
      connection = cmd.delete :connection
      connection ||= @client.aquire_connection

      options = {}
      options[:query] = cmd

      Monga::CallbackCursor.new(connection, name, "$cmd", options).first do |err, resp|
        res = make_response(err, resp, ret_blk, resp_blk)
        unless ret_blk
          return res 
        end
      end
    end

    # Helper to choose how to return result.
    # If callback is provided it will be passed there.
    # Otherwise error will be raised and result will be returned with a `return`
    #
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
          resp
        end
      end
    end

    # Blank result should be interpreted as an error. Ok so.
    # 
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