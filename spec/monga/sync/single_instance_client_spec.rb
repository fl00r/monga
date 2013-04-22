require 'spec_helper'

describe Monga::Clients::SingleInstanceClient do
  before do
    EM.synchrony do
      @instance = Fake::SingleInstance.new(29000)
      @client = Monga::Client.new port: 29000, type: :sync
      @collection = @client["dbTest"]["myCollection"]
      EM.stop
    end
  end

  it "should fail on disconnect and reconnect when instance is up again" do
    EM.synchrony do
      @instance.start
      @collection.safe_insert(name: "Peter")
      @instance.stop
      proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
      proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
      @instance.start
      @collection.safe_insert(name: "Madonna")
      EM.stop
    end
  end
end