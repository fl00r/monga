require 'spec_helper'

describe Monga::Clients::SingleInstanceClient do
  before do
    EM.synchrony do
      INSTANCE.start
      @client = Monga::Client.new(type: :sync)
      @collection = @client["dbTest"]["testCollection"]
      @collection.safe_remove
      EM.stop
    end
  end

  it "should fail on disconnect and reconnect then" do
    EM.synchrony do
      @collection.safe_insert(name: "Peter")
      INSTANCE.stop
      proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
      INSTANCE.start
      @collection.safe_insert(name: "Madonna")
      @collection.count.must_equal 2
      EM.stop
    end
  end
end