require "eventmachine"
require "bson"
require "logger"

module Monga
  DEFAULT_HOST = "127.0.0.1"
  DEFAULT_PORT = 27017
  HEADER_SIZE  = 16
  
  extend self

  def logger
    @logger ||= begin
      l = Logger.new(STDOUT)
      l.level = Logger::DEBUG
      l
    end
  end
end

require File.expand_path("../monga/connection", __FILE__)
require File.expand_path("../monga/connection_pool", __FILE__)
require File.expand_path("../monga/database", __FILE__)
require File.expand_path("../monga/collection", __FILE__)
require File.expand_path("../monga/miner", __FILE__)
require File.expand_path("../monga/cursor", __FILE__)
require File.expand_path("../monga/exceptions", __FILE__)
require File.expand_path("../monga/response", __FILE__)
require File.expand_path("../monga/request", __FILE__)
require File.expand_path("../monga/clients/client", __FILE__)
require File.expand_path("../monga/clients/replica_set_client", __FILE__)
require File.expand_path("../monga/clients/master_slave_client", __FILE__)