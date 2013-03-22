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
      Monga::Requests::Query.new(self, query: cmd).callback_perform
    end

    def full_name
      [name, "$cmd"] * "."
    end
  end
end