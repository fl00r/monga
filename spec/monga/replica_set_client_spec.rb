require 'spec_helper'

describe Monga::ReplicaSetClient do
  include Helpers::Truncate

  it "should establish simple connection" do
    EM.run do
      client = Monga::ReplicaSetClient.new(servers: REPL_SET_PORTS)
      db = client["dbTest"]
      collection = db["testCollection"]
      1.times do
        collection.insert({row: "test"})
      end
      EM.add_timer(0.3) do
        req = collection.count
        req.callback do |n|
          # n.must_equal 100
          collection.safe_delete.callback do
            EM.stop
          end
        end
        req.errback do |err|
          raise err
        end
      end
    end
  end
end