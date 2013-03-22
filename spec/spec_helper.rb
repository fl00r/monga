LIB_PATH = File.expand_path('../../lib/monga',  __FILE__)

require LIB_PATH
require 'helpers/truncate'
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new

EM.run do
  CONNECTION = Monga::Connection.connect(host: "localhost", port: 27017)
  DB = CONNECTION["dbTest"]
  COLLECTION = DB["testCollection"]
  EM.stop
end