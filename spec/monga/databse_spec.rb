require 'spec_helper'

describe Monga::Database do
  include Helpers::Truncate

  it "should run simple cmd" do
    EM.run do
      10.times do |i|
        COLLECTION.insert({ test: i })
      end
      req = DB.cmd({ count: "testCollection" })
      req.callback do |r| 
        r["n"].must_equal(10.0)
        EM.stop
      end
      req.errback{ |err| raise err; EM.stop }
    end
  end
end