require 'spec_helper'

describe Monga::Clients::ReplicaSetClient do
  before do
    @thread = Thread.new do
      EM.run do
        @replset = Fake::ReplicaSet.new([29000, 29100, 29200])
        @replset.start_all
      end
    end
    sleep 0.1
    @client = Monga::Client.new servers: ['127.0.0.1:29000', '127.0.0.1:29100', '127.0.0.1:29200'], type: :block, timeout: 1
    @collection = @client["dbTest"]["myCollection"]
  end

  after do
    EM.stop if EM.reactor_running?
    @thread.join
  end

  it "should fail on disconnect and reconnect when primary is up again" do
    sleep(0.1)
    @replset.start_all
    sleep(0.1)
    @collection.safe_insert(name: "Peter")
    @replset.primary.stop
    proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
    proc{ @collection.safe_insert(name: "Peter") }.must_raise Timeout::Error
    proc{ @collection.safe_insert(name: "Peter") }.must_raise Timeout::Error
    @replset.primary.start
    sleep(0.1)
    @collection.safe_insert(name: "Madonna")
    @collection.safe_insert(name: "Madonna")
    @collection.safe_insert(name: "Madonna")
  end

  it "should work even if secondaries down" do
    sleep(0.1)
    @replset.start_all
    @collection.safe_insert(name: "Peter")
    @collection.safe_insert(name: "Peter")
    @replset.secondaries.each(&:stop)
    @collection.safe_insert(name: "Peter")
    @collection.safe_insert(name: "Peter")
  end

  it "should find new primary if it is down" do
    sleep(0.1)
    @replset.start_all
    @collection.safe_insert(name: "Peter")
    @replset.primary.stop
    proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
    proc{ @collection.safe_insert(name: "Peter") }.must_raise Timeout::Error
    proc{ @collection.safe_insert(name: "Peter") }.must_raise Timeout::Error
    @replset.vote
    @collection.safe_insert(name: "Madonna")
  end
end