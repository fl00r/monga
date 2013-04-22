require 'spec_helper'

describe Monga::Clients::SingleInstanceClient do
  before do
    EM.synchrony do
      @client = Monga::Client.new port: 29000, type: :block
      @collection = @client["dbTest"]["myCollection"]
      @instance = Fake::SingleInstance.new(29000)
      EM.stop
    end
    @t = Thread.new do
      EM.run do
        @instance.start
      end
    end
  end

  after do
    EM.stop
    @t.join
  end

  it "should fail on disconnect and reconnect when instance is up again" do
    @collection.safe_insert(name: "Peter")
    @instance.stop
    proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
    proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
    @instance.start
    @collection.safe_insert(name: "Madonna")
  end
end