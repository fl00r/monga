require 'spec_helper'

describe Monga::Clients::SingleInstanceClient do
  before do
    INSTANCE.start
    @client = Monga::Client.new(type: :block)
    @collection = @client["dbTest"]["testCollection"]
    @collection.safe_remove
  end

  it "should fail on disconnect and reconnect then" do
    @collection.safe_insert(name: "Peter")
    INSTANCE.stop
    proc{ @collection.safe_insert(name: "Peter") }.must_raise Monga::Exceptions::Disconnected
    INSTANCE.start
    @collection.safe_insert(name: "Madonna")
    @collection.count.must_equal 2
  end
end