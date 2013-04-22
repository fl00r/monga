LIB_PATH = File.expand_path('../../lib/monga',  __FILE__)

require LIB_PATH
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new

Monga.logger.level = Logger::ERROR

require 'helpers/mongodb'