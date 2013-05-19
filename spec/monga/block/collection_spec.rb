require 'spec_helper'

describe Monga::Collection do
  before do
    @client = Monga::Client.new(type: :block, pool_size: 10)
    @db = @client["dbTest"]
    @collection = @db["testCollection"]
    @collection.safe_remove
    docs = []
    10.times do |i|
      docs << { artist: "Madonna", title: "Track #{i+1}" }
      docs << { artist: "Radiohead", title: "Track #{i+1}" }
    end
    @collection.safe_insert(docs)
  end

  # QUERY

  describe "query" do
    it "should fetch all documents" do
      docs = @collection.find.all
      docs.size.must_equal 20
    end

    it "should fetch all docs with skip and limit" do
      docs = @collection.find.skip(10).limit(4).all
      docs.size.must_equal 4
    end

    it "should fetch first" do
      doc = @collection.first
      doc.keys.must_equal ["_id", "artist", "title"]
    end
  end

  # INSERT

  describe "insert" do
    before do
      @collection.safe_ensure_index({ "personal_id" => 1 }, { unique: true, sparse: true })
    end

    after do
      @collection.drop_index( personal_id: 1 )
    end

    it "should insert single doc" do
      doc = { name: "Peter", age: 18 }
      @collection.safe_insert(doc)
      resp = @collection.find(name: "Peter").all
      resp.size.must_equal 1
      resp.first["age"].must_equal 18
    end

    it "should insert batch of docs" do
      docs = [{ name: "Peter", age: 18 }, {name: "Jhon", age: 18}]
      @collection.safe_insert(docs)
      resp = @collection.find(age: 18).all
      resp.size.must_equal 2
    end

    it "should fail on uniq index" do
      docs = [{ name: "Peter", age: 18, personal_id: 20 }, {name: "Jhon", age: 18, personal_id: 20}, {name: "Rebeca", age: 21, personal_id: 5}]
      proc{ @collection.safe_insert(docs) }.must_raise Monga::Exceptions::QueryFailure
      @collection.count.must_equal 21
    end

    it "should continue_on_error" do
      docs = [{ name: "Peter", age: 18, personal_id: 20 }, {name: "Jhon", age: 18, personal_id: 20}, {name: "Rebeca", age: 21, personal_id: 5}]
      proc{ @collection.safe_insert(docs, continue_on_error: true) }.must_raise Monga::Exceptions::QueryFailure
      @collection.count.must_equal 22
    end
  end

  # UPDATE

  describe "update" do
    it "should make simple update (first matching)" do
      @collection.safe_update({ artist: "Madonna" }, { "$set" => { country: "USA" } })
      @collection.count( query: { artist: "Madonna", country: "USA" }).must_equal 1
    end

    it "should create non existing item (upsert)" do
      @collection.safe_update({ artist: "Bjork" }, { "$set" => { country: "Iceland" } }, { upsert: true }) 
      @collection.count(query: { artist: "Bjork" }).must_equal 1
    end

    it "should update all matching data (multi_update)" do
      @collection.safe_update({ artist: "Madonna" }, { "$set" => { country: "USA" } }, {multi_update: true})
      docs = @collection.find(artist: "Madonna").all
      docs.each{ |d| d["country"].must_equal "USA" }
    end
  end

  # REMOVE

  describe "remove" do
    it "should delete all matching docs" do
      @collection.safe_delete(artist: "Madonna")
      @collection.count(query: { artist: "Madonna" }).must_equal 0
    end

    it "should delete first matching doc (single_remove)" do
      @collection.safe_delete({ artist: "Madonna" }, single_remove: true)
      @collection.count(query: { artist: "Madonna" }).must_equal 9
    end
  end

  # COUNT

  describe "count" do
    it "should count all docs" do
      @collection.count.must_equal 20
    end

    it "should count all docs with query" do
      @collection.count(query: { artist: "Madonna" }).must_equal 10
    end

    it "should count all docs with limit" do
      @collection.count(query: { artist: "Madonna" }, limit: 5).must_equal 5
    end

    it "should count all docs with limit and skip" do
      @collection.count(query: { artist: "Madonna" }, limit: 5, skip: 6).must_equal 4
    end
  end

  # ENSURE/DROP INDEX

  describe "ensure_index" do
    before do
      @collection.drop_indexes
    end

    it "should create index" do
      @collection.safe_ensure_index(title: 1)
      docs = @collection.get_indexes
      docs.any?{ |doc| doc["key"] == {"title" => 1}}.must_equal true
    end

    it "should create sparse index" do
      @collection.safe_ensure_index({ title: 1 }, sparse: true)
      docs = @collection.get_indexes
      docs.any?{ |doc| doc["key"] == {"title" => 1} && doc["sparse"] == true }.must_equal true
    end

    it "should create unique index" do
      @collection.safe_ensure_index({ some_field: 1 }, unique: true, sparse: true)
      docs = @collection.get_indexes
      docs.any?{ |doc| doc["key"] == {"some_field" => 1} && doc["unique"] == true }.must_equal true
    end

    it "should drop single index" do
      @collection.safe_ensure_index(title: 1)
      docs = @collection.get_indexes
      docs.any?{ |doc| doc["key"] == {"title" => 1}}.must_equal true
      @collection.drop_index(title: 1)
      docs = @collection.get_indexes
      docs.any?{ |doc| doc["key"] == {"title" => 1}}.must_equal false
    end

    it "should drop all indexes (except primary on _id)" do
      @collection.safe_ensure_index(title: 1)
      docs = @collection.get_indexes
      docs.any?{ |doc| doc["key"] == {"title" => 1}}.must_equal true
      @collection.drop_indexes
      docs = @collection.get_indexes
      docs.select{ |d| d["ns"] == "dbTest.testCollection" }.size.must_equal 1
    end
  end

  # MAP/REDUCE

  describe "map_reduce" do
    before do
      @collection.safe_remove
      5.times do |i|
        @collection.safe_insert(title: "The Book", count: i)
      end
    end

    it "should run map reduce" do
      map_func = "function() {
                    emit(this.title, this.count);
                  };"
      red_func = "function(docTitle, docCount) {
                    return Array.sum(docCount);
                  };"
      @collection.map_reduce(map: map_func, reduce: red_func, out: {inline: 1} )["results"].first["value"].must_equal 10.0
    end
  end

  # AGGREGATE, GROUP, DISTINCT

  describe "aggregate, group, distinct" do

  end

  # TEXT SEARCH

  # Travis.ci doesn't support text search in mongodb
  # describe "text search" do
  #   before do
  #     @collection.safe_ensure_index(author: "text")
  #     @collection.safe_insert(author: "Lady Gaga", track: "No. 1")
  #     @collection.safe_insert(author: "Lady Gaga", track: "No. 2")
  #     @collection.safe_insert(author: "Madonna", track: "No. 1")
  #   end

  #   it "should find some tracks" do
  #     @collection.text("Lady")["results"].map{ |r| r["obj"]["track"] }.sort.must_equal ["No. 1", "No. 2"]
  #     @collection.text("Madonna")["results"].map{ |r| r["obj"]["track"] }.sort.must_equal ["No. 1"]
  #   end
  # end
end