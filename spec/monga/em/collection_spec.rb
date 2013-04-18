require 'spec_helper'

describe Monga::Collection do
  before do
    EM.run do
      @client = Monga::Client.new(type: :em, pool_size: 10)
      @db = @client["dbTest"]
      @collection = @db["testCollection"]
      @collection.safe_remove do |err, resp|
        raise err if err
        docs = []
        10.times do |i|
          docs << { artist: "Madonna", title: "Track #{i+1}" }
          docs << { artist: "Radiohead", title: "Track #{i+1}" }
        end
        @collection.safe_insert(docs) do |err|
          raise err if err
          EM.stop
        end
      end
    end
  end

  # QUERY

  describe "query" do
    it "should fetch all documents" do
      EM.run do
        @collection.find.all do |err, docs|
          docs.size.must_equal 20
          EM.stop
        end
      end
    end

    it "should fetch all docs with skip and limit" do
      EM.run do
        @collection.find.skip(10).limit(4).all do |err, docs|
          docs.size.must_equal 4
          EM.stop
        end
      end
    end

    it "should fetch first" do
      EM.run do
        @collection.first do |err, doc|
          doc.keys.must_equal ["_id", "artist", "title"]
          EM.stop
        end
      end
    end
  end

  # INSERT

  describe "insert" do
    before do
      EM.run do
        @collection.safe_ensure_index({ "personal_id" => 1 }, { unique: true, sparse: true }) do |err, resp|
          raise err if err
          EM.stop
        end
      end
    end

    after do
      EM.run do
        @collection.drop_index( personal_id: 1 ) do |err, resp|
          raise err if err
          EM.stop
        end
      end
    end

    it "should insert single doc" do
      EM.run do
        doc = { name: "Peter", age: 18 }
        @collection.safe_insert(doc) do |err, resp|
          @collection.find(name: "Peter").all do |err, resp|
            resp.size.must_equal 1
            resp.first["age"].must_equal 18
            EM.stop
          end
        end
      end
    end

    it "should insert batch of docs" do
      EM.run do
        docs = [{ name: "Peter", age: 18 }, {name: "Jhon", age: 18}]
        @collection.safe_insert(docs) do |err, resp|
          @collection.find(age: 18).all do |err, resp|
            resp.size.must_equal 2
            EM.stop
          end
        end
      end
    end

    it "should fail on uniq index" do
      EM.run do
        docs = [{ name: "Peter", age: 18, personal_id: 20 }, {name: "Jhon", age: 18, personal_id: 20}, {name: "Rebeca", age: 21, personal_id: 5}]
        @collection.safe_insert(docs) do |err, resp|
          (Monga::Exceptions::QueryFailure === err).must_equal true
          @collection.count do |err, cnt|
            cnt.must_equal 21
            EM.stop
          end
        end
      end
    end

    it "should continue_on_error" do
      EM.run do
        docs = [{ name: "Peter", age: 18, personal_id: 20 }, {name: "Jhon", age: 18, personal_id: 20}, {name: "Rebeca", age: 21, personal_id: 5}]
        @collection.safe_insert(docs, continue_on_error: true) do |err, resp|
          (Monga::Exceptions::QueryFailure === err).must_equal true
          @collection.count do |err, cnt|
            cnt.must_equal 22
            EM.stop
          end
        end
      end
    end
  end

  # UPDATE

  describe "update" do
    it "should make simple update (first matching)" do
      EM.run do
        @collection.safe_update({ artist: "Madonna" }, { "$set" => { country: "USA" } }) do |err, resp|
          @collection.count( query: { artist: "Madonna", country: "USA" }) do |err, count|
            count.must_equal 1
            EM.stop
          end
        end
      end
    end

    it "should create non existing item (upsert)" do
      EM.run do
        @collection.safe_update({ artist: "Bjork" }, { "$set" => { country: "Iceland" } }, { upsert: true }) do |err, resp|
          @collection.count(query: { artist: "Bjork" }) do |err, cnt|
            cnt.must_equal 1
            EM.stop
          end
        end
      end
    end

    it "should update all matching data (multi_update)" do
      EM.run do
        @collection.safe_update({ artist: "Madonna" }, { "$set" => { country: "USA" } }, {multi_update: true}) do |err, resp|
          @collection.find(artist: "Madonna").all do |err, docs|
            docs.each{ |d| d["country"].must_equal "USA" }
            EM.stop
          end
        end
      end
    end
  end

  # REMOVE

  describe "remove" do
    it "should delete all matching docs" do
      EM.run do
        @collection.safe_delete(artist: "Madonna") do
          @collection.count(query: { artist: "Madonna" }) do |err, cnt|
            cnt.must_equal 0
            EM.stop
          end
        end
      end
    end

    it "should delete first matching doc (single_remove)" do
      EM.run do
        @collection.safe_delete({ artist: "Madonna" }, single_remove: true) do
          @collection.count(query: { artist: "Madonna" }) do |err, cnt|
            cnt.must_equal 9
            EM.stop
          end
        end
      end
    end
  end

  # COUNT

  describe "count" do
    it "should count all docs" do
      EM.run do
        @collection.count do |err, count|
          count.must_equal 20
          EM.stop
        end
      end
    end

    it "should count all docs with query" do
      EM.run do
        @collection.count(query: { artist: "Madonna" }) do |err, count|
          count.must_equal 10
          EM.stop
        end
      end
    end

    it "should count all docs with limit" do
      EM.run do
        @collection.count(query: { artist: "Madonna" }, limit: 5) do |err, count|
          count.must_equal 5
          EM.stop
        end
      end
    end

    it "should count all docs with limit and skip" do
      EM.run do
        @collection.count(query: { artist: "Madonna" }, limit: 5, skip: 6) do |err, count|
          count.must_equal 4
          EM.stop
        end
      end
    end
  end

  # ENSURE/DROP INDEX

  describe "ensure_index" do
    before do
      EM.run do
        @collection.drop_indexes do |err, resp|
          raise err if err
          EM.stop
        end
      end
    end

    it "should create index" do
      EM.run do
        @collection.safe_ensure_index(title: 1) do
          @collection.get_indexes do |err, docs|
            docs.any?{ |doc| doc["key"] == {"title" => 1}}.must_equal true
            EM.stop
          end
        end
      end
    end

    it "should create sparse index" do
      EM.run do
        @collection.safe_ensure_index({ title: 1 }, sparse: true) do
          @collection.get_indexes do |err, docs|
            docs.any?{ |doc| doc["key"] == {"title" => 1} && doc["sparse"] == true }.must_equal true
            EM.stop
          end
        end
      end
    end

    it "should create unique index" do
      EM.run do
        @collection.safe_ensure_index({ some_field: 1 }, unique: true, sparse: true) do |err, resp|
          @collection.get_indexes do |err, docs|
            docs.any?{ |doc| doc["key"] == {"some_field" => 1} && doc["unique"] == true }.must_equal true
            EM.stop
          end
        end
      end
    end

    it "should drop single index" do
      EM.run do
        @collection.safe_ensure_index(title: 1) do
          @collection.get_indexes do |err, docs|
            docs.any?{ |doc| doc["key"] == {"title" => 1}}.must_equal true
            @collection.drop_index(title: 1) do
              @collection.get_indexes do |err, docs|
                docs.any?{ |doc| doc["key"] == {"title" => 1}}.must_equal false
                EM.stop
              end
            end
          end
        end
      end
    end

    it "should drop all indexes (except primary on _id)" do
      EM.run do
        @collection.safe_ensure_index(title: 1) do
          @collection.get_indexes do |err, docs|
            docs.any?{ |doc| doc["key"] == {"title" => 1}}.must_equal true
            @collection.drop_indexes do |err|
              @collection.get_indexes do |err, docs|
                docs.select{ |d| d["ns"] == "dbTest.testCollection" }.size.must_equal 1
                EM.stop
              end
            end
          end
        end
      end
    end
  end
end