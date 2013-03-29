require 'spec_helper'

describe Monga::ReplicaSetClient do
  include Helpers::Truncate

  it "should establish simple connection" do
    EM.run do
      servers = [
        { host: "127.0.0.1", port: 29100 },
        { host: "127.0.0.1", port: 29200 },
        { host: "127.0.0.1", port: 29300 },
      ]
      client = Monga::ReplicaSetClient.new(servers: servers)
      p client.primary
      EM.add_timer(1){
        puts client.clients.map(&:primary?)
      }
    end
  end
end
# mongod --port 29100 --dbpath /tmp/mongodb/rs0-0 --replSet rs1
# mongod --port 29200 --dbpath /tmp/mongodb/rs0-1 --replSet rs1
# mongod --port 29300 --dbpath /tmp/mongodb/rs0-2 --replSet rs1

# rsconf = {
#            _id: "rs1",
#            members: [
#                       {
#                        _id: 0,
#                        host: "127.0.0.1:29100"
#                       }
#                     ]
#          }
# rs.initiate( {
#            _id: "rs1",
#            members: [
#                       {
#                        _id: 0,
#                        host: "127.0.0.1:29100"
#                       }
#                     ]
#          } )
# rs.conf()
# rs.add("127.0.0.1:29200")
# rs.add("127.0.0.1:29300")