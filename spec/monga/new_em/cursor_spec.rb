require 'spec_helper'

describe Monga::Cursor do
  before do
    EM.run do
      @client = Monga::Client.new(type: :em, pool_size: 10, servers: ["188.93.61.42:27017", "188.93.61.42:27018", "188.93.61.42:27019"])
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

  # ALL

  describe "all" do
    it "should find all" do
      EM.run do
        @collection.find.all do |err, docs|
          docs.size.must_equal 20
          EM.stop
        end
      end
    end

    it "should find all with query" do
      EM.run do
        @collection.find(artist: "Madonna").all do |err, docs|
          docs.size.must_equal 10
          docs.each{ |d| d["artist"].must_equal "Madonna" }
          EM.stop
        end
      end
    end

    it "should find all with limit" do
      EM.run do
        @collection.find.limit(5).all do |err, docs|
          docs.size.must_equal 5
          EM.stop
        end
      end
    end

    it "should find all with batch size" do
      EM.run do
        @collection.find.batch_size(2).all do |err, docs|
          docs.size.must_equal 20
          EM.stop
        end
      end
    end

    it "should find all with skip" do
      EM.run do
        @collection.find.skip(10).all do |err, docs|
          docs.size.must_equal 10
          EM.stop
        end
      end
    end
  end

  # FIRST

  describe "first" do
    it "should fetch first with sort" do
      EM.run do
        @collection.find.sort(title: 1).first do |err, doc|
          doc["title"].must_equal "Track 1"
          EM.stop
        end
      end
    end

    it "should fetch first with sort and skip" do
      EM.run do
        @collection.find.sort(title: 1).skip(2).first do |err, doc|
          doc["title"].must_equal "Track 10"
          EM.stop
        end
      end
    end
  end

  # NEXT_BATCH

  describe "next_batch" do
    it "should fetch batches" do
      EM.run do
        cursor = @collection.find.batch_size(2).limit(3)
        cursor.next_batch do |err, batch, more|
          batch.size.must_equal 2
          more.must_equal true
          cursor.next_batch do |err, batch, more|
            batch.size.must_equal 1
            more.must_equal false
            EM.stop
          end
        end
      end
    end
  end

  # EACH_BATCH

  describe "each_batch" do
    it "should fetch 3 items by batches" do
      EM.run do
        docs = []
        @collection.find.batch_size(2).limit(3).each_batch do |err, batch, iter|
          if iter
            docs += batch
            iter.next
          else
            docs.size.must_equal 3
            EM.stop
          end
        end
      end
    end
  end

  # NEXT_DOC

  describe "next_doc" do
    it "should fetch doc by doc" do
      EM.run do
        cursor = @collection.find.limit(3).batch_size(2)
        cursor.next_doc do |err, doc, more|
          more.must_equal true
          cursor.next_doc do |err, doc, more|
            cursor.next_doc do |err, doc, more|
              more.must_equal false
              EM.stop
            end
          end
        end
      end
    end
  end

  # EACH_DOC

  describe "each_doc" do
    it "should iterate over some docs" do
      EM.run do
        docs = []
        @collection.find.limit(100).skip(15).batch_size(3).each_doc do |err, doc, iter|
          if iter
            docs << doc
            iter.next
          else
            docs.size.must_equal 5
            EM.stop
          end
        end
      end
    end

    it "should iterate over all docs" do
      EM.run do
        docs = []
        @collection.find.batch_size(3).each_doc do |err, doc, iter|
          if iter
            docs << doc
            iter.next
          else
            docs.size.must_equal 20
            EM.stop
          end
        end
      end
    end
  end

  # KILL CURSOR

  describe "kill" do
    it "should work with kill" do
      EM.run do
        cursor = @collection.find
        cursor.next_batch do |err, batch, more|
          cursor.kill
          cursor.next_batch do |err, batch, more|
            (Monga::Exceptions::ClosedCursor === err).must_equal true
            EM.stop
          end
        end
      end
    end
  end

  # TAILABLE CURSOR

  describe "tailable cursor" do
    before do
      EM.run do
        @capped = @db["testCapped"]
        @db.create_collection("testCapped", capped: true, size: 4*1024) do |err, resp|
          raise err if err
          @capped.safe_insert(title: "Test") do |err, resp|
            raise err if err
            EM.stop
          end
        end
      end
    end

    after do
      EM.run do
        @capped.drop do |err, resp|
          raise err if err
          EM.stop
        end
      end
    end

    it "should be tailable" do
      EM.run do
        tailable_cursor = @capped.find.flag(tailable_cursor: true)
        docs = []
        tailable_cursor.each_doc do |err, res, iter|
          if iter
            if res
              docs << res
              if docs.size == 2
                docs.map{ |d| d["title"] }.must_equal ["Test", "New!"]
                EM.stop
              else
                iter.next
              end
            else
              @capped.safe_insert(title: "New!") do |err, res|
                iter.next
              end
            end
          end
        end
      end
    end
  end
end