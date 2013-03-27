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
        cursor = COLLECTION.find.batch_size(2).cursor
        req = cursor.next_batch
        req.callback do |batch|
          batch.size.must_equal 2
          batch.first.tap{|d| d.delete "_id" }.must_equal({ "author" => "Madonna", "title" => "Burning Up" })
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end

    it "should return next document" do
      EM.run do
        cursor = COLLECTION.find.batch_size(2).cursor
        req = cursor.next_document
        req.callback do |doc|
          doc.tap{|d| d.delete "_id" }.must_equal({ "author" => "Madonna", "title" => "Burning Up" })
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

  describe "fetch many data" do
    before do
      MANY = 1000
      EM.run do
        req = COLLECTION.safe_insert(
          MANY.times.map{ |i| { row: (i+1).to_s } }
        )
        req.callback{ EM.stop }
        req.errback{ |err| raise err }
      end
    end

    it "should fetch em all and count" do
      EM.run do
        req = COLLECTION.find
        req.callback do |docs|
          docs.size.must_equal MANY
          COLLECTION.count.callback do |c|
            c.must_equal MANY
            EM.stop
          end
        end
        req.errback{ |err| raise err }
      end
    end
  end

  describe "insert" do
    it "should single insert" do
      EM.run do
        COLLECTION.insert(todo: "shopping")
        EM.add_timer(0.05) do
          req = COLLECTION.first
          req.callback do |resp|
            resp["todo"].must_equal "shopping"
            EM.stop
          end
          req.errback{ |err| raise err }
        end
      end
    end

    it "should safe_insert" do
      EM.run do
        req = COLLECTION.safe_insert(todo: "shopping")
        req.callback do
          req = COLLECTION.first
          req.callback do |resp|
            resp["todo"].must_equal "shopping"
            EM.stop
          end
          req.errback{ |err| raise err }
        end
        req.errback{ |err| raise err }
      end
    end

    it "should batch insert" do
      EM.run do
        req = COLLECTION.safe_insert([{todo: "shopping"}, {todo: "walking"}, {todo: "dinner with Scarlett"}])
        req.callback do
          req = COLLECTION.find
          req.callback do |resp|
            resp.size.must_equal 3
            resp.map{|r| r["todo"]}.must_equal ["shopping", "walking", "dinner with Scarlett"]
            EM.stop
          end
          req.errback{ |err| raise err }
        end
        req.errback{ |err| raise err }
      end
    end

    it "should fail on uniq index" do
      EM.run do
        COLLECTION.ensure_index({book_id: 1}, {unique: true})
        req = COLLECTION.safe_insert([{book_id: 1, title: "Bible"}, {book_id: 1, title: "Lord of the Ring"}, {book_id: 2, title: "War and Piece"}, {book_id: 3, title: "Harry Potter"}])
        req.callback do
          fail "It should never happen"
        end
        req.errback do |err|
          err.class.must_equal Monga::Exceptions::QueryFailure
          COLLECTION.count.callback do |n|
            n.must_equal 1
            EM.stop
          end
        end
      end
    end

    it "should continue to insert if error happend" do
      EM.run do
        COLLECTION.ensure_index({book_id: 1}, {unique: true})
        req = COLLECTION.safe_insert([{book_id: 1, title: "Bible"}, {book_id: 1, title: "Lord of the Ring"}, {book_id: 2, title: "War and Piece"}, {book_id: 3, title: "Harry Potter"}], {continue_on_error: true})
        req.callback do |res|
          fail "It should never happen"
        end
        req.errback do |err|
          COLLECTION.count.callback do |n|
            n.must_equal 3
            EM.stop
          end
        end
      end
    end
  end

  describe "indexes" do
    it "should create an index" do
      EM.run do
        COLLECTION.ensure_index(artist: 1)
        req = COLLECTION.get_indexes
        req.callback do |indexes|
          indexes.any?{ |ind| ind["ns"] == "#{DB.name}.#{COLLECTION.name}" && ind["key"] == {"artist" => 1}}.must_equal true
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end

    it "should drop an index" do
      EM.run do
        COLLECTION.ensure_index(artist: 1)
        req = COLLECTION.drop_index(artist: 1)
        req.callback do |resp|
          req = COLLECTION.get_indexes
          req.callback do |indexes|
            indexes.any?{ |ind| ind["ns"] == "#{DB.name}.#{COLLECTION.name}" && ind["key"] == {"artist" => 1}}.must_equal false
            EM.stop
          end
          req.errback{ |err| raise err }
        end
        req.errback{ |err| raise err }
      end
    end

    it "should create unique index" do
      EM.run do
        COLLECTION.ensure_index({artist: 1}, {unique: 1})
        req = COLLECTION.get_indexes
        req.callback do |indexes|
          indexes.any?{ |ind| ind["ns"] == "#{DB.name}.#{COLLECTION.name}" && ind["key"] == {"artist" => 1} && ind["unique"] == true}.must_equal true
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end

    # Why somebody needs to do safe_ensure_index?
    it "should not fail on safe_ensure_index" do
      EM.run do
        req = COLLECTION.safe_ensure_index({artist: 1}, {unique: 1})
        req.callback do |res|
          req.callback{ |res| EM.stop }
          req.errback{ |err| raise err }
        end
        req.errback{ |err| raise err }
      end
    end
  end

  describe "update" do
    before do
      EM.run do
        COLLECTION.safe_insert([
          { artist: "Madonna", title: "Burning Up", status: "Out of Order" },
          { artist: "Madonna", title: "Freezing", status: "Out of Order" }
        ]).callback{ EM.stop }
      end
    end

    it "should update exist item (first matching)" do
      EM.run do
        req = COLLECTION.safe_update({artist: "Madonna"}, {artist: "Madonna", status: "Available"})
        req.callback do |res|
          COLLECTION.find.callback do |docs|
            d = docs.first
            d.delete("_id")
            d.must_equal({"artist" => "Madonna", "status" => "Available"})
            docs.last["status"].must_equal "Out of Order"
            EM.stop
          end
        end
      end
    end

    it "should update exist item (all matching, multi_update)" do
      EM.run do
        req = COLLECTION.safe_update({artist: "Madonna"}, {"$set" => { status: "Available"}}, {multi_update: true})
        req.callback do |res|
          COLLECTION.find.callback do |docs|
            docs.map{|d| [d["artist"], d["status"]]}.must_equal([["Madonna", "Available"], ["Madonna", "Available"]])
            EM.stop
          end
        end
        req.errback{ |err| raise err }
      end
    end

    it "should do nothing on update non existing item" do
      EM.run do
        req = COLLECTION.safe_update({artist: "Madonna2"}, {status: "Available"})
        req.callback do |res|
          req = COLLECTION.find(artist: "Madonna2").callback do |docs|
            docs.size.must_equal 0
            EM.stop
          end
        end
        req.errback do |err|
          raise err
        end
      end
    end

    it "should create non existing item (upsert)" do
      EM.run do
        req = COLLECTION.safe_update({artist: "Madonna2"}, {"$set" => {status: "Available"}}, {upsert: true})
        req.callback do |res|
          req = COLLECTION.find(artist: "Madonna2").callback do |docs|
            docs.size.must_equal 1
            docs.first["artist"].must_equal("Madonna2")
            docs.first["status"].must_equal("Available")
            EM.stop
          end
        end
        req.errback do |err|
          raise err
        end
      end
    end
  end
end