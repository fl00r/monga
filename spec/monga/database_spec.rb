require 'spec_helper'

describe Monga::Database do
  describe "create/drop" do
    it "should create and then drop collection" do
      EM.run do
        req = DB.create_collection("myCollection")
        req.errback{ |err| raise err }
        req.callback do
          req = DB.list_collections
          req.errback{ |err| raise err }
          req.callback do |res|
            res.include?("myCollection").must_equal true
            req = DB.drop_collection("myCollection")
            req.errback{ |err| raise err }
            req.callback do
              req = DB.list_collections
              req.errback{ |err| raise err }
              req.callback do |res|
                res.include?("myCollection").must_equal false
                EM.stop
              end
            end
          end
        end
      end
    end
  end

  describe "create collection with options" do
    it "should create cappet collection with 5kb size to store only 1 large doc" do
      EM.run do
        req = DB.create_collection("myCollection", capped: true, size: 5*1024)
        req.callback do
          collection = DB["myCollection"]
          str = "h"*4*1024
          req = collection.safe_insert({ data: str })
          req.errback{ |err| raise err }
          req.callback do
            req = collection.safe_insert({ data: str })
            req.errback{ |err| raise err }
            req.callback do
              req = collection.count()
              req.errback{ |err| raise err }
              req.callback do |res|
                res.must_equal 1
                req = DB.drop_collection("myCollection")
                req.callback{ EM.stop }
              end
            end
          end
        end
      end
    end
  end
end