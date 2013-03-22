require 'spec_helper'

describe Monga::Connection do
  describe "One instance" do
    it "should try to connect to stopped instance then instance is started and connection became connected" do
      EM.run do
        system MONGODB_STOP
        connection = Monga::Connection.connect( host: "localhost", port: 27017 )
        EM.next_tick do
          connection.connected?.must_equal false
          system MONGODB_START
          EM.add_timer(0.5) do
            puts connection.connected?.must_equal true
            EM.stop
          end
        end
      end
    end

    it "should retrieve connection after restarting of EventMacine" do
      connection = nil
      EM.run do
        connection = Monga::Connection.connect( host: "localhost", port: 27017 )
        EM.next_tick do 
          connection.connected?.must_equal true
          EM.stop
        end
      end
      connection.connected?.must_equal false
      EM.run do
        # Somebody tries to send data
        # Driver should automatically reconnect
        connection["dbTest"].get_last_error
        EM.add_timer(0.1) do
          connection.connected?.must_equal true
          EM.next_tick{ EM.stop }
        end
      end
    end

    it "should receive errback while trying to fetch data from stopped mongo" do
      EM.run do
        connection = Monga::Connection.connect( host: "localhost", port: 27017 )
        system MONGODB_STOP
        req = connection["dbTest"].get_last_error
        req.callback{ |r| puts "never executed" }
        req.errback do |err| 
          err.class.must_equal Monga::Exceptions::LostConnection
          EM.stop
        end
      end
      system MONGODB_START
      sleep(0.5) # Give Mongodb chance to start for next test
    end
  end

  describe "Replica Set connection" do
    # TODO
  end

  describe  "Master Slave connection" do
    # TODO
  end
end