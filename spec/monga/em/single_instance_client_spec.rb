require 'spec_helper'

describe Monga::Clients::SingleInstanceClient do
  before do
    EM.run do
      INSTANCE.start
      @client = Monga::Client.new(type: :em)
      @collection = @client["dbTest"]["testCollection"]
      @collection.safe_remove do
        EM.stop
      end
    end
  end

  it "should fail on disconnect and reconnect then" do
    EM.run do
      @collection.safe_insert(name: "Peter") do
        INSTANCE.stop
        @collection.safe_insert(name: "Peter") do |err, msg|
          err.class.must_equal Monga::Exceptions::Disconnected
          INSTANCE.start
          @collection.safe_insert(name: "Madonna") do
            @collection.count do |err, cnt|
              cnt.must_equal 2
              EM.stop
            end
          end
        end
      end
    end
  end
end