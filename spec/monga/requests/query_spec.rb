require 'spec_helper'

describe Monga::Requests::Query do
  include Helpers::Truncate
  
  describe "simple query" do
    it "should return first item from database" do
      EM.run do
        req = Monga::Requests::Query.new(COLLECTION, { limit: 1 }).callback_perform
        req.callback{ |r| p r; EM.stop }
        req.errback{ |err| raise err; EM.stop }
      end
    end
  end
end