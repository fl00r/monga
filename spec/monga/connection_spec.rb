require 'spec_helper'
require 'helpers/synchrony'

describe Monga::Connection do
  it "should establish connection synchronously" do
    connection = Monga::Connection.new(port: 27017, type: :sync, timeout: 1)
    EM.next_tick do
      connection.connected?.must_equal true
    end
  end

  it "should establish connection asyncronously" do
    connection = Monga::Connection.new(port: 27017, type: :em, timeout: 1)
    EM.next_tick do
      connection.connected?.must_equal true
    end
  end
end