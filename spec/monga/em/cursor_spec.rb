require 'spec_helper'

describe Monga::Cursor do
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
          docs += batch
          if iter
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
          docs << doc
          if iter
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
          docs << doc
          if iter
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
end