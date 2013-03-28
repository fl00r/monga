require 'spec_helper'

describe Monga::Cursor do
  include Helpers::Truncate

  describe "simple ops" do
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
      EM.run do
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

    it "should select all with batch_size option" do
      EM.run do
        cursor = Monga::Cursor.new(DB, COLLECTION.name, { query: { author: "Madonna" }, batch_size: 2 })
        docs = []
        cursor.each_doc do |doc|
          docs << doc
        end
        cursor.callback do |res|
          docs.size.must_equal 7
          docs.all?{ |doc| doc["author"] == "Madonna" }.must_equal true
          EM.stop
        end
        cursor.errback{ |err| raise err }
      end
    end

    it "should select LIMIT < max with batch_size option" do
      EM.run do
        cursor = Monga::Cursor.new(DB, COLLECTION.name, { query: { author: "Madonna" }, batch_size: 2, limit: 5 })
        docs = []
        cursor.each_doc do |doc|
          docs << doc
        end
        cursor.callback do
          docs.size.must_equal 5
          docs.all?{ |doc| doc["author"] == "Madonna" }.must_equal true
          EM.stop
        end
        cursor.errback{ |err| raise err }
      end
    end

    it "should select LIMIT > max with batch_size option" do
      EM.run do
        cursor = Monga::Cursor.new(DB, COLLECTION.name, { query: { author: "Madonna" }, batch_size: 2, limit: 15 })
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

    it "should kill cursor" do
      EM.run do
        cursor = Monga::Cursor.new(DB, COLLECTION.name, { query: { author: "Madonna" }, batch_size: 2, limit: 15 })
        cursor.next_document.callback do |doc|
          cursor.next_document.callback do |doc|
            DB.cmd(cursorInfo: 1).callback do |resp|
              resp.first["totalOpen"].must_equal 1
              cursor.kill
              DB.cmd(cursorInfo: 1).callback do |resp|
                resp.first["totalOpen"].must_equal 0
                req = cursor.next_document
                req.callback do |resp|
                  fail "never called"
                end
                req.errback do |err|
                  err.class.must_equal Monga::Exceptions::CursorIsClosed
                  EM.stop
                end
              end
            end
          end
        end
      end
    end

    it "should kill marked cursors" do
      EM.run do
        cursor = Monga::Cursor.new(DB, COLLECTION.name, { query: { author: "Madonna" }, batch_size: 2, limit: 15 })
        cursor.next_document
        DB.cmd(cursorInfo: 1).callback do |resp|
          cursor.mark_to_kill
          resp.first["totalOpen"].must_equal 1
          EM.add_timer(2) do
            DB.cmd(cursorInfo: 1).callback do |resp|
              resp.first["totalOpen"].must_equal 0
              EM.stop
            end
          end
        end
      end
    end
  end
end