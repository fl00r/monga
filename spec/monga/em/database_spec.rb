require 'spec_helper'

describe Monga::Database do
  before do
    EM.run do
      @client = Monga::Client.new(type: :em)
      @db = @client["dbTest"]
      @collection = @db["testCollection"]
      @collection.safe_remove do
        EM.stop
      end
    end
  end

  after do
    EM.run do
      @collection.safe_remove do
        EM.stop
      end
    end
  end

  it "should create and drop collection" do
    EM.run do
      @db.create_collection("cappedCollection") do |err, resp|
        @db.list_collections do |err, resp|
          resp["retval"].must_include "cappedCollection"
          @db.drop_collection("cappedCollection") do
            @db.list_collections do |err, resp|
              resp["retval"].wont_include "cappedCollection"
              EM.stop
            end
          end
        end
      end
    end
  end

  it "should count in collection" do
    EM.run do
      @collection.safe_insert([{ title: 1 }, { title: 2 }]) do
        @db.count("testCollection") do |err, cnt|
          cnt.must_equal 2
          EM.stop
        end
      end
    end
  end

  it "should eval javascript" do
    EM.run do
      @db.eval("1+1") do |err, resp|
        resp["retval"].must_equal 2.0
        EM.stop
      end
    end
  end

  # INDEXES

  describe "indexes" do
    before do
      EM.run do
        @db.drop_indexes("testCollection", "*") do
          EM.stop
        end
      end
    end

    it "should drop index" do
      EM.run do
        @collection.safe_ensure_index(title: 1) do
          @collection.get_indexes do |err, resp|
            resp.select{ |i| i["ns"] == "dbTest.testCollection" }.size.must_equal 2
            @db.drop_indexes("testCollection", title: 1) do
              @collection.get_indexes do |err, resp|
                resp.select{ |i| i["ns"] == "dbTest.testCollection" }.size.must_equal 1
                EM.stop
              end
            end
          end
        end
      end
    end
  end

  # GET LAST ERROR

  describe "getLastError" do
    before do
      EM.run do
        @collection.drop_indexes do
          @collection.safe_ensure_index({ personal_id: 1 }, { unique: true, sparse: true }) do
            EM.stop
          end
        end
      end
    end

    it "should get last error" do
      EM.run do
        req = @collection.insert(name: "Peter", personal_id: 10)
        @db.get_last_error(req.connection) do |err, resp|
          resp["ok"].must_equal 1.0
          req = @collection.insert(name: "Peter", personal_id: 10)
          @db.get_last_error(req.connection) do |err, resp|
            err.class.must_equal Monga::Exceptions::QueryFailure
            EM.stop
          end
        end
      end
    end

    it "should getLastError with fsync" do
      EM.run do
        req = @collection.insert(name: "Peter", personal_id: 10)
        @db.get_last_error(req.connection, fsync: true) do |err, resp|
          resp["ok"].must_equal 1.0
          req = @collection.insert(name: "Peter", personal_id: 10)
          @db.get_last_error(req.connection, fsync: true) do |err, resp|
            err.class.must_equal Monga::Exceptions::QueryFailure
            EM.stop
          end
        end
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