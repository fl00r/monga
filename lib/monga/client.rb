require File.expand_path("../clients/client", __FILE__)
require File.expand_path("../clients/replica_set_client", __FILE__)
require File.expand_path("../clients/master_slave_client", __FILE__)
module Monga
  Client = Monga::Clients::Client
  ReplicaSetClient = Monga::Clients::ReplicaSetClient
  MasterSlaveClient = Monga::Clients::MasterSlaveClient
end