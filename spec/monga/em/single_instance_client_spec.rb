require 'spec_helper'

describe Monga::Clients::SingleInstanceClient do
  before do
    EM.synchrony do
      @client = Monga::Client.new port: 29000, type: :em
      @collection = @client["dbTest"]["myCollection"]
      @instance = Fake::SingleInstance.new(29000)
      EM.stop
    end
  end

  it "should fail on disconnect and reconnect when instance is up again" do
    EM.synchrony do
      @instance.start
      @collection.safe_insert(name: "Peter") do
        @instance.stop
        @collection.safe_insert(name: "Peter") do |err, resp|
          err.class.must_equal Monga::Exceptions::Disconnected
          @instance.start
          @collection.safe_insert(name: "Madonna") do
            EM.stop
          end
        end
      end
    end
  end
end