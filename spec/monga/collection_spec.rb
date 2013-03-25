require 'spec_helper'

describe Monga::Collection do
  include Helpers::Truncate

  describe "queries" do
    before do
      EM.run do
        req = COLLECTION.safe_insert([
          { author: "Madonna", title: "Burning Up" },
          { author: "Madonna", title: "Freezing" },
          { author: "Madonna", title: "Untitled Track 1" },
          { author: "Madonna", title: "Untitled Track 2" },
          { author: "Madonna", title: "Untitled Track 3" },
          { author: "Madonna", title: "Untitled Track 4" },
          { author: "Madonna", title: "Untitled Track 5" },
          { author: "Radiohead", title: "Karma Police" },
        ])
        req.callback{ EM.stop }
        req.errback{ |err| raise err }
      end
    end

    it "should find all" do
      EM.run do
        req = COLLECTION.find
        req.callback do |data|
          data.size.must_equal 8
          data.first.tap{|d| d.delete "_id" }.must_equal({ "author" => "Madonna", "title" => "Burning Up" })
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end

    it "should findOne aka first" do
      EM.run do
        req = COLLECTION.first
        req.callback do |data|
          data.tap{|d| d.delete "_id" }.must_equal({ "author" => "Madonna", "title" => "Burning Up" })
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end

    it "should find limit" do
      EM.run do
        req = COLLECTION.find.limit(2)
        req.callback do |data|
          data.size.must_equal 2
          data.first.tap{|d| d.delete "_id" }.must_equal({ "author" => "Madonna", "title" => "Burning Up" })
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end

    it "should find skip" do
      EM.run do
        req = COLLECTION.find.limit(3).skip(2)
        req.callback do |data|
          data.size.must_equal 3
          data.first.tap{|d| d.delete "_id" }.must_equal({ "author" => "Madonna", "title" => "Untitled Track 1" })
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end

    it "should find with batch_size" do
      EM.run do
        req = COLLECTION.find.batch_size(2)
        req.callback do |data|
          data.size.must_equal 8
          data.first.tap{|d| d.delete "_id" }.must_equal({ "author" => "Madonna", "title" => "Burning Up" })
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end

    it "should find with skip limit and query" do
      EM.run do
        req = COLLECTION.find(author: "Madonna").limit(10).skip(2)
        req.callback do |data|
          data.size.must_equal 5
          data.first.tap{|d| d.delete "_id" }.must_equal({ "author" => "Madonna", "title" => "Untitled Track 1" })
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end

    it "should return nothing" do
      EM.run do
        req = COLLECTION.find(author: "Bjork")
        req.callback do |data|
          data.size.must_equal 0
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end

    it "should return specific fields" do
      EM.run do
        req = COLLECTION.find({author: "Madonna"}, { author: 1 })
        req.callback do |data|
          data.size.must_equal 7
          p data.map(&:keys).flatten.uniq.must_equal(["_id", "author"])
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end

  end
end