require 'spec_helper'

describe Monga::Connection do

  it "should establish connection blocking" do
    connection = Monga::Connection.new(port: 27017, type: :block, timeout: 1)
    connection.connected?.must_equal true
  end
end