require 'spec_helper'

describe Monga::Clients::ReplicaSetClient do
  before do
    EM.synchrony do
      @replset = Fake::ReplicaSet.new([39000, 39100, 39200])
      @client = Monga::Client.new servers: ['127.0.0.1:39000', '127.0.0.1:39100', '127.0.0.1:39200'], type: :sync, timeout: 1
      @collection = @client["dbTest"]["myCollection"]
      EM.stop
    end
  end

  it "should fail on disconnect and reconnect when primary is up again" do
    EM.synchrony do
      @replset.start_all
      @collection.safe_insert(name: "Peter")
      @replset.primary.stop
      proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
      proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
      EM.add_timer(0.5) do
        @replset.primary.start
      end
      @collection.safe_insert(name: "Peter")
      @collection.safe_insert(name: "Madonna")
      EM.stop
    end
  end

  it "should work even if secondaries down" do
    EM.synchrony do
      @replset.start_all
      @collection.safe_insert(name: "Peter")
      @collection.safe_insert(name: "Peter")
      @replset.secondaries.each(&:stop)
      @collection.safe_insert(name: "Peter")
      @collection.safe_insert(name: "Peter")
      EM.stop
    end
  end

  it "should find new primary if it is down" do
    EM.synchrony do
      @replset.start_all
      @collection.safe_insert(name: "Peter")
      @replset.primary.stop
      proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
      proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
      proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
      @replset.vote
      @collection.safe_insert(name: "Madonna")
      EM.stop
    end
  end
end