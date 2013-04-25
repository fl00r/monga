require 'spec_helper'

describe Monga::Clients::ReplicaSetClient do
  before do
    EM.run do
      @replset = Fake::ReplicaSet.new([39000, 39100, 39200])
      @client = Monga::Client.new servers: ['127.0.0.1:39000', '127.0.0.1:39100', '127.0.0.1:39200'], type: :em, timeout: 1
      @collection = @client["dbTest"]["myCollection"]
      @replset.start_all
      EM.stop
    end
  end

  it "should fail on disconnect and reconnect when primary is up again" do
    EM.run do
      @replset.start_all
      @collection.safe_insert(name: "Peter") do |err, resp|
        @replset.primary.stop
        @collection.safe_insert(name: "Peter") do |err, resp|
          err.class.must_equal Monga::Exceptions::Disconnected
          @collection.safe_insert(name: "Peter") do |err, resp|
            err.class.must_equal Monga::Exceptions::Disconnected
            @collection.safe_insert(name: "Peter") do |err, resp|
              err.class.must_equal Monga::Exceptions::Disconnected
              @replset.primary.start
              @collection.safe_insert(name: "Madonna") do |err, resp|
                err.must_equal nil
                @collection.safe_insert(name: "Madonna") do |err, resp|
                  err.must_equal nil
                  @collection.safe_insert(name: "Madonna") do |err|
                    err.must_equal nil
                    EM.stop
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  it "should work even if secondaries down" do
    EM.run do
      @replset.start_all
      @collection.safe_insert(name: "Peter") do |err|
        err.must_equal nil
        @collection.safe_insert(name: "Peter") do |err|
          err.must_equal nil
          @replset.secondaries.each(&:stop)
          @collection.safe_insert(name: "Peter") do |err|
            err.must_equal nil
            @collection.safe_insert(name: "Peter") do |err|
              err.must_equal nil

              EM.stop
            end
          end
        end
      end
    end
  end

  it "should find new primary if it is down" do
    EM.run do
      @replset.start_all
      @collection.safe_insert(name: "Peter") do |err|
        err.must_equal nil
        @replset.primary.stop
        @collection.safe_insert(name: "Peter") do |err|
          err.class.must_equal Monga::Exceptions::Disconnected
          @collection.safe_insert(name: "Peter") do |err|
            err.class.must_equal Monga::Exceptions::Disconnected
            @collection.safe_insert(name: "Peter") do |err|
              err.class.must_equal Monga::Exceptions::Disconnected
              @replset.vote
              @collection.safe_insert(name: "Madonna") do |err|
                err.must_equal nil
                EM.stop
              end
            end
          end
        end
      end
    end
  end
end