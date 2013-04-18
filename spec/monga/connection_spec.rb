require 'spec_helper'

describe Monga::Connection do
  it "should establish connection synchronously" do
    EM.run do
      connection = Monga::Connection.new(port: 27017, type: :sync, timeout: 1)
      EM.next_tick do
        connection.connected?.must_equal true
        EM.stop
      end
    end
  end

  it "should establish connection asyncronously" do
    EM.run do 
      connection = Monga::Connection.new(port: 27017, type: :em, timeout: 1)
      EM.next_tick do
        connection.connected?.must_equal true
        EM.stop
      end
    end
  end
end