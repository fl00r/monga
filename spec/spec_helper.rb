LIB_PATH = File.expand_path('../../lib/monga',  __FILE__)

require LIB_PATH
require 'helpers/truncate'
require 'helpers/mongodb'
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new

EM.run do
  CLIENT = Monga::Client.new(host: "localhost", port: 27017)
  DB = CLIENT["dbTest"]
  COLLECTION = DB["testCollection"]
  EM.stop
end

INSTANCE = Mongodb::Instance.new(dbpath: "/tmp/mongodb/instance/")

REPL_SET_PORTS = [{ port: 29100 }, { port: 29200 }, { port: 29300 }]
EM.run do
  REPL_SET = Mongodb::ReplicaSet.new(REPL_SET_PORTS)
  EM.stop
end

# And welcome to callback Hell