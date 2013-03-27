require 'spec_helper'

describe Monga::ConnectionPool do
  include Helpers::Truncate
  before do
    EM.run do
      CONNECTION_POOL = Monga::ConnectionPool.new(pool_size: 2)
      POOL_DB = CONNECTION_POOL["dbTest"]
      POOL_COLLECTION = POOL_DB["testCollection"]
      EM.stop
    end
  end

  it "should aquire connections correctly" do
    EM.run do
      conns = []
      req = POOL_COLLECTION.safe_insert(artist: "Madonna")
      100.times do
        conns << CONNECTION_POOL.aquire_connection
      end
      conns.uniq.size.must_equal 1
      req.callback do
        100.times{ conns << CONNECTION_POOL.aquire_connection }
        conns.uniq.size.must_equal 2
        EM.stop
      end
      req.errback{ |err| raise err }
    end
  end

  it "should aquire connections correctly when there are waiting responses on each connection" do
    EM.run do
      conns = []
      POOL_COLLECTION.safe_insert(artist: "Madonna")
      POOL_COLLECTION.safe_insert(artist: "Madonna")
      100.times do
        conns << CONNECTION_POOL.aquire_connection
      end
      conns.uniq.size.must_equal 2
      CONNECTION_POOL.connections.all?{|c| c.responses.size == 1}.must_equal true
      EM.stop
    end
  end
end