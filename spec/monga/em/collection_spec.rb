require 'spec_helper'

describe Monga::Collection do
  describe "primary" do
    before do
      EM.run do
        @client = Monga::Client.new(type: :em, pool_size: 10, servers: ["127.0.0.1:27017", "127.0.0.1:27018", "127.0.0.1:27019"])
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

    # MAP/REDUCE

    describe "map_reduce" do
      before do
        EM.run do
          @collection.safe_remove do
            docs = []
            5.times do |i|
              docs << { title: "The Book", count: i }
            end
            @collection.safe_insert(docs) do
              EM.stop
            end
          end
        end
      end

      it "should run map reduce" do
        EM.run do
          map_func = "function() {
                        emit(this.title, this.count);
                      };"
          red_func = "function(docTitle, docCount) {
                        return Array.sum(docCount);
                      };"
          @collection.map_reduce(map: map_func, reduce: red_func, out: {inline: 1} ) do |err, res|
            res["results"].first["value"].must_equal 10.0
            EM.stop
          end
        end
      end
    end

    # AGGREGATE, GROUP, DISTINCT

    describe "aggregate, group, distinct" do

    end

    # TEXT SEARCH

    # Travis.ci doesn't support text search in mongodb
    # describe "text search" do
    #   before do
    #     EM.run do
    #       @collection.safe_ensure_index(author: "text") do
    #         @collection.safe_insert([
    #           { author: "Lady Gaga", track: "No. 1" },
    #           { author: "Lady Gaga", track: "No. 2" },
    #           { author: "Madonna", track: "No. 1" }
    #         ]) do
    #           EM.stop
    #         end
    #       end
    #     end
    #   end

    #   it "should find some tracks" do
    #     EM.run do
    #       @collection.text("Lady") do |err, res|
    #         res["results"].map{ |r| r["obj"]["track"] }.sort.must_equal ["No. 1", "No. 2"]
    #         @collection.text("Madonna") do |err, res|
    #           res["results"].map{ |r| r["obj"]["track"] }.sort.must_equal ["No. 1"]
    #           EM.stop
    #         end
    #       end
    #     end
    #   end
    # end
  end

  describe "secondary" do
    before do
      @primary_client = Monga::Client.new(type: :block, pool_size: 10, servers: ["127.0.0.1:27017", "127.0.0.1:27018", "127.0.0.1:27019"], read_pref: :primary)
      @secondary_client = Monga::Client.new(type: :block, pool_size: 10, servers: ["127.0.0.1:27017", "127.0.0.1:27018", "127.0.0.1:27019"], read_pref: :secondary)
      @primary_db = @primary_client["dbTest"]
      @primary_collection = @primary_db["testCollection"]
      @primary_collection.safe_remove
      docs = []
      10.times do |i|
        docs << { artist: "Madonna", title: "Track #{i+1}" }
        docs << { artist: "Radiohead", title: "Track #{i+1}" }
      end
      @primary_collection.safe_insert(docs)
      @secondary_db = @secondary_client["dbTest"]
      @secondary_collection = @secondary_db["testCollection"]
    end

    it "should fail on count on slave" do
      proc{ @secondary_collection.count(query: { artist: "Madonna" }, limit: 5, skip: 6) }.must_raise Monga::Exceptions::QueryFailure
    end

    it "should run with slave_ok" do
      @secondary_collection.count(query: { artist: "Madonna" }, limit: 5, skip: 6, slave_ok: true).must_equal 4
    end
  end
end