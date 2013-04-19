require 'spec_helper'

describe Monga::Database do
  before do
    EM.synchrony do
      @client = Monga::Client.new
      @db = @client["dbTest"]
      @collection = @db["testCollection"]
      @collection.safe_remove
      EM.stop
    end
  end

  after do
    EM.synchrony do
      @collection.safe_remove
      EM.stop
    end
  end

  it "should create and drop collection" do
    EM.synchrony do
      @db.create_collection("cappedCollection")
      @db.list_collections["retval"].must_include "cappedCollection"
      @db.drop_collection("cappedCollection")
      @db.list_collections["retval"].wont_include "cappedCollection"
      EM.stop
    end
  end

  it "should count in collection" do
    EM.synchrony do
      @collection.safe_insert([{ title: 1 }, { title: 2 }])
      @db.count("testCollection").must_equal 2
      EM.stop
    end
  end

  it "should eval javascript" do
    EM.synchrony do
      @db.eval("1+1")["retval"].must_equal 2.0
      EM.stop
    end
  end

  # INDEXES

  describe "indexes" do
    before do
      EM.synchrony do
        @db.drop_indexes("testCollection", "*")
        EM.stop
      end
    end

    it "should drop index" do
      EM.synchrony do
        @collection.safe_ensure_index(title: 1)
        @collection.get_indexes.select{ |i| i["ns"] == "dbTest.testCollection" }.size.must_equal 2
        @db.drop_indexes("testCollection", title: 1)
        @collection.get_indexes.select{ |i| i["ns"] == "dbTest.testCollection" }.size.must_equal 1
        EM.stop
      end
    end
  end

  # GET LAST ERROR

  describe "getLastError" do
    before do
      EM.synchrony do
        @collection.drop_indexes
        @collection.safe_ensure_index({ personal_id: 1 }, { unique: true, sparse: true })
        EM.stop
      end
    end

    it "should get last error" do
      EM.synchrony do
        req = @collection.insert(name: "Peter", personal_id: 10)
        @db.get_last_error(req.connection)["ok"].must_equal 1.0
        req = @collection.insert(name: "Peter", personal_id: 10)
        @db.get_last_error(req.connection).class.must_equal Monga::Exceptions::QueryFailure
        EM.stop
      end
    end

    it "should getLastError with fsync" do
      EM.synchrony do
        req = @collection.insert(name: "Peter", personal_id: 10)
        @db.get_last_error(req.connection, fsync: true)["ok"].must_equal 1.0
        req = @collection.insert(name: "Peter", personal_id: 10)
        @db.get_last_error(req.connection, fsync: true).class.must_equal Monga::Exceptions::QueryFailure
        EM.stop
      end
    end
  end

  # AGGREGATION

  describe "aggregation" do
    it "should aggregate"
  end

  # MAP REDUCE

  describe "map reduce" do
    it "should run map reduce"
  end
end