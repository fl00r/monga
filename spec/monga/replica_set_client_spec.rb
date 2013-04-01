require 'spec_helper'

describe Monga::ReplicaSetClient do
  include Helpers::Truncate

  it "should establish simple connection" do
    EM.run do
      100.times do
        RS_COLLECTION.insert({row: "test"})
      end
      EM.add_timer(0.1) do
        req = RS_COLLECTION.count
        req.callback do |n|
          n.must_equal 100
          EM.stop
        end
        req.errback do |err|
          raise err
        end
      end
    end
  end

  it "should find new primary" do
    EM.run do
      n = 0
      EM.add_periodic_timer(0.01) do
        if n == 101
          n += 1
          RS_COLLECTION.count.callback do |cnt|
            cnt.must_equal 100
            EM.stop
          end
        elsif n <= 100
          if n == 10
            primary = REPL_SET.primary
            primary.stop
            primary.start
          end
          n+= 1
          RS_COLLECTION.insert({row: n.to_s})
        end
      end
    end
  end
end