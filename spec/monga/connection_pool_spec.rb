require 'spec_helper'

describe Monga::ConnectionPool do
  # include Helpers::Truncate
  before do
    INSTANCE.start
    EM.run do
      @client = Monga::Client.new(pool_size: 2)
      @db = @client["dbTest"]
      @collection = @db["testCollection"]
      EM.stop
    end
  end

  it "should aquire connections correctly" do
    EM.run do
      conns = []
      req = @collection.safe_insert(artist: "Madonna")
      EM.next_tick do
        100.times do
          conns << @client.aquire_connection
        end
        conns.uniq.size.must_equal 1
        req.callback do
          100.times{ conns << @client.aquire_connection }
          conns.uniq.size.must_equal 2
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end
  end

  it "should aquire connections correctly when there are waiting responses on each connection" do
    EM.run do
      conns = []
      @collection.safe_insert(artist: "Madonna")
      @collection.safe_insert(artist: "Madonna")
      100.times do
        conns << @client.aquire_connection
      end
      conns.uniq.size.must_equal 2
      @client.connection_pool.connections.all?{|c| c.responses.size == 1}.must_equal true
      EM.stop
    end
  end
end