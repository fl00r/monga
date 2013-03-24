require 'spec_helper'

describe Monga::Cursor do
  include Helpers::Truncate

  describe "simple ops" do
    before do
      EM.run do
        req = COLLECTION.insert([
          { author: "Madonna", title: "Burning Up" },
          { author: "Madonna", title: "Freezing" },
          { author: "Madonna", title: "Untitled Track 1" },
          { author: "Madonna", title: "Untitled Track 2" },
          { author: "Madonna", title: "Untitled Track 3" },
          { author: "Madonna", title: "Untitled Track 4" },
          { author: "Madonna", title: "Untitled Track 5" },
          { author: "Radiohead", title: "Karma Police" },
        ])
        EM.add_timer(0.05){ EM.next_tick{ EM.stop } }
      end
    end

    it "should return one item" do
      EM.run do
        cursor = Monga::Cursor.new(DB, COLLECTION.name, { query: { author: "Madonna" }, limit: 1 }, {})
        docs = []
        cursor.each_doc do |doc|
          docs << doc
        end
        cursor.callback do
          docs.first["title"].must_equal "Burning Up"
          EM.stop
        end
        cursor.errback{ |err| raise err }
      end
    end

    it "should return two items" do
      EM.run do
        cursor = Monga::Cursor.new(DB, COLLECTION.name, { query: { author: "Madonna" }, limit: 2 }, {})
        docs = []
        cursor.each_doc do |doc|
          docs << doc
        end
        cursor.callback do
          docs.size.must_equal 2
          docs.first["title"].must_equal "Burning Up"
          docs.last["title"].must_equal "Freezing"
          EM.stop
        end
        cursor.errback{ |err| raise err }
      end
    end

    it "should skip two items" do
      EM.run do
        cursor = Monga::Cursor.new(DB, COLLECTION.name, { query: { author: "Madonna" }, limit: 2, skip: 2 })
        docs = []
        cursor.each_doc do |doc|
          docs << doc
        end
        cursor.callback do
          docs.size.must_equal 2
          docs.first["title"].must_equal "Untitled Track 1"
          docs.last["title"].must_equal "Untitled Track 2"
          EM.stop
        end
        cursor.errback{ |err| raise err }
      end
    end

    it "should select all" do
        cursor = Monga::Cursor.new(DB, COLLECTION.name, { query: { author: "Madonna" } })
        docs = []
        cursor.each_doc do |doc|
          docs << doc
        end
        cursor.callback do
          docs.size.must_equal 7
          docs.all?{ |doc| doc["author"] == "Madonna" }.must_equal true
          EM.stop
        end
        cursor.errback{ |err| raise err }
    end
  end
end