require 'spec_helper'
require 'helpers/synchrony'

describe Monga::ConnectionPool do
  it "should establish connection synchronously" do
    connection_pool = Monga::ConnectionPool.new(port: 27017, type: :sync, timeout: 1, pool_size: 10)
    EM.next_tick do
      connection_pool.connections.each do |conn|
        conn.connected?.must_equal true
      end
    end
  end
end