module Monga
  class Collection
    attr_reader :name, :db

    def initialize(db, name)
      @db = db
      @name = name
    end

    def query(query = {}, fields = {}, opts = {})
      options = {}
      options[:query] = query
      options[:fields] = fields
      options.merge! opts
      Monga::Miner.new(db, name, options)
    end
    alias :find :query

    def find_one(query = {}, fields = {}, opts = {})
      options = {}
      options[:query] = query
      options[:fields] = fields
      options.merge! opts

      Monga::Response.surround do |resp|
        req = Monga::Miner.new(db, name, options).limit(1).all
        req.callback{ |data| resp.succeed data.first }
        req.errback{ |err| resp.fail err }
      end
    end
    alias :first :find_one

    def insert(documents, opts = {})
      options = {}
      options[:documents] = documents
      options.merge!(opts)
      Monga::Requests::Insert.new(@db, @name, options).perform
    end

    def update(query = {}, update = {}, flags = {})
      options = {}
      options[:query] = query
      options[:update] = update
      options.merge!(flags)
      Monga::Requests::Update.new(@db, @name, options).perform
    end

    def delete(query = {}, opts = {})
      options = {}
      options[:query] = query
      options.merge!(opts)
      Monga::Requests::Delete.new(@db, @name, options).perform
    end
    alias :remove :delete

    def ensure_index(keys, opts={})
      doc = {}
      doc.merge!(opts)
      # Read docs about naming
      doc[:name] ||= keys.to_a.flatten * "_"
      doc[:key] = keys
      doc[:ns] = "#{db.name}.#{name}"
      Monga::Requests::Insert.new(@db, "system.indexes", {documents: doc}).perform
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
      @db.count(@name)
    end

    # Safe methods
    [:update, :insert, :delete, :remove, :ensure_index].each do |meth|
      class_eval <<-EOS
        def safe_#{meth}(*args)
          safe do
            #{meth}(*args)
          end
        end
      EOS
    end

    def safe
      Monga::Response.surround do |response|
        request_id = yield
        req = @db.get_last_error
        req.callback do |data|
          response.succeed(request_id)
        end
        req.errback{ |err| response.fail(err) }
      end
    end
  end
end