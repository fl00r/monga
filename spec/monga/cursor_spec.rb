require 'spec_helper'

describe Monga::Cursor do
  include Helpers::Truncate

  describe "simple ops" do
    before do
      EM.run do
        req = COLLECTION.insert(author: "Madonna", title: "Burning Up")
        req = COLLECTION.insert(author: "Madonna", title: "Freezing")
        req = COLLECTION.insert(author: "Radiohead", title: "Karma Police")
        EM.add_timer(0.05){ EM.next_tick{ EM.stop } }
      end
    end

    it "should return one item" do
      EM.run do
        query = { author: "Madonna" }
        select_options = {}
        cursor = Monga::Cursor.new(COLLECTION, query, select_options).limit(1)
        cursor.callback do |resp|
          resp[0]["title"].must_equal "Burning Up"
          EM.stop
        end
        cursor.errback{ |err| raise err }
      end
    end

    it "should return two items" do
      EM.run do
        query = { author: "Madonna" }
        select_options = {}
        cursor = Monga::Cursor.new(COLLECTION, query, select_options).limit(2)
        cursor.callback do |resp|
          resp[0]["title"].must_equal "Burning Up"
          resp[1]["title"].must_equal "Freezing"
          EM.stop
        end
        cursor.errback{ |err| raise err }
      end
    end
  end
end