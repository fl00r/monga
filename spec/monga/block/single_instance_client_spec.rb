require 'spec_helper'

describe Monga::Clients::SingleInstanceClient do
  before do
    @client = Monga::Client.new port: 28000, type: :block
    @collection = @client["dbTest"]["myCollection"]
    @thread = Thread.new do
      EM.run do
        @instance = Fake::SingleInstance.new(28000)
        @instance.start
      end
    end
  end

  after do
    EM.stop
    @thread.join
  end

  it "should fail on disconnect and reconnect when instance is up again" do
    sleep(0.1) # wait till instance started 
    @collection.safe_insert(name: "Peter")
    @instance.stop
    proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
    proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
    @instance.start
    @collection.safe_insert(name: "Madonna")
  end
end