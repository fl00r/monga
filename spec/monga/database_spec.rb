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
            res["retval"].include?("myCollection").must_equal true
            req = DB.drop_collection("myCollection")
            req.errback{ |err| raise err }
            req.callback do
              req = DB.list_collections
              req.errback{ |err| raise err }
              req.callback do |res|
                res["retval"].include?("myCollection").must_equal false
                EM.stop
              end
            end
          end
        end
      end
    end
  end
end