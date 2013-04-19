LIB_PATH = File.expand_path('../../lib/monga',  __FILE__)

require LIB_PATH
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new

Monga.logger.level = Logger::ERROR

require 'helpers/mongodb'

INSTANCE = Mongodb::Instance.new(dbpath: "/tmp/mongodb/instance/")
# REPL_SET_PORTS = [{ port: 29100 }, { port: 29200 }, { port: 29300 }]
# REPL_SET = Mongodb::ReplicaSet.new(REPL_SET_PORTS)