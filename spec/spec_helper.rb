LIB_PATH = File.expand_path('../../lib/monga',  __FILE__)

require LIB_PATH
require 'helpers/truncate'
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

MONGODB_START = "sudo service mongodb start"
MONGODB_STOP = "sudo service mongodb stop"

# And welcome to callback Hell