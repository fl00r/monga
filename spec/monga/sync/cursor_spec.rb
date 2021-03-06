require 'spec_helper'

describe Monga::Cursor do
  before do
    EM.synchrony do
      @client = Monga::Client.new(type: :sync, pool_size: 10)
      @db = @client["dbTest"]
      @collection = @db["testCollection"]
      @collection.safe_remove
      docs = []
      10.times do |i|
        docs << { artist: "Madonna", title: "Track #{i+1}" }
        docs << { artist: "Radiohead", title: "Track #{i+1}" }
      end
      @collection.safe_insert(docs)
      EM.stop
    end
  end

  # ALL

  describe "all" do
    it "should find all" do
      EM.synchrony do
        docs = @collection.find.all
        docs.size.must_equal 20
        EM.stop
      end
    end

    it "should find all with query" do
      EM.synchrony do
        docs = @collection.find(artist: "Madonna").all
        docs.size.must_equal 10
        docs.each{ |d| d["artist"].must_equal "Madonna" }
        EM.stop
      end
    end

    it "should find all with limit" do
      EM.synchrony do
        docs = @collection.find.limit(5).all
        docs.size.must_equal 5
        EM.stop
      end
    end

    it "should find all with batch size" do
      EM.synchrony do
        docs = @collection.find.batch_size(2).all
        docs.size.must_equal 20
        EM.stop
      end
    end

    it "should find all with skip" do
      EM.synchrony do
        docs = @collection.find.skip(10).all
        docs.size.must_equal 10
        EM.stop
      end
    end
  end

  # FIRST

  describe "first" do
    it "should fetch first with sort" do
      EM.synchrony do
        doc = @collection.find.sort(title: 1).first
        doc["title"].must_equal "Track 1"
        EM.stop
      end
    end

    it "should fetch first with sort and skip" do
      EM.synchrony do
        doc = @collection.find.sort(title: 1).skip(2).first
        doc["title"].must_equal "Track 10"
        EM.stop
      end
    end
  end

  # NEXT_BATCH

  describe "next_batch" do
    it "should fetch batches" do
      EM.synchrony do
        cursor = @collection.find.batch_size(2).limit(3)
        batch, more = cursor.next_batch
        batch.size.must_equal 2
        more.must_equal true
        batch, more = cursor.next_batch
        batch.size.must_equal 1
        more.must_equal false
        EM.stop
      end
    end
  end

  # EACH_BATCH

  describe "each_batch" do
    it "should fetch 3 items by batches" do
      EM.synchrony do
        docs = []
        @collection.find.batch_size(2).limit(3).each_batch do |batch|
          docs += batch
        end
        docs.size.must_equal 3
        EM.stop
      end
    end
  end

  # NEXT_DOC

  describe "next_doc" do
    it "should fetch doc by doc" do
      EM.synchrony do
        cursor = @collection.find.limit(3).batch_size(2)
        doc, more = cursor.next_doc
        more.must_equal true
        doc, more = cursor.next_doc
        doc, more = cursor.next_doc
        more.must_equal false
        EM.stop
      end
    end
  end

  # # EACH_DOC

  describe "each_doc" do
    it "should iterate over some docs" do
      EM.synchrony do
        docs = []
        @collection.find.limit(100).skip(15).batch_size(3).each_doc do |doc|
          docs << doc
        end
        docs.size.must_equal 5
        EM.stop
      end
    end

    it "should iterate over all docs" do
      EM.synchrony do
        docs = []
        @collection.find.batch_size(3).each_doc do |doc|
          docs << doc
        end
        docs.size.must_equal 20
        EM.stop
      end
    end
  end

  # KILL CURSOR

  describe "kill" do
    it "should work with kill" do
      EM.synchrony do
        cursor = @collection.find
        batch, more = cursor.next_batch
        cursor.kill
        proc{ cursor.next_batch }.must_raise Monga::Exceptions::ClosedCursor
        EM.stop
      end
    end
  end

  # TAILABLE CURSOR

  describe "tailable cursor" do
    before do
      EM.synchrony do
        @capped = @db["testCapped"]
        @db.create_collection("testCapped", capped: true, size: 4*1024)
        @capped.safe_insert(title: "Test")
        EM.stop
      end
    end

    after do
      EM.synchrony do
        @capped.drop
        EM.stop
      end
    end

    it "should be tailable" do
      EM.synchrony do
        tailable_cursor = @capped.find.flag(tailable_cursor: true)
        docs = []
        tailable_cursor.each_doc do |doc|
          @capped.safe_insert(title: "New!")
          if doc
            docs << doc
            if docs.size == 2
              docs.map{ |d| d["title"] }.must_equal ["Test", "New!"]
              break
            end
          end
        end
        tailable_cursor.kill
        EM.stop
      end
    end
  end
end