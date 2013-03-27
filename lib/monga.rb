require "eventmachine"
require "bson"
require "logger"

require File.expand_path("../monga/connection", __FILE__)
require File.expand_path("../monga/connection_pool", __FILE__)
require File.expand_path("../monga/database", __FILE__)
require File.expand_path("../monga/collection", __FILE__)
require File.expand_path("../monga/miner", __FILE__)
require File.expand_path("../monga/cursor", __FILE__)
require File.expand_path("../monga/exceptions", __FILE__)
require File.expand_path("../monga/response", __FILE__)
require File.expand_path("../monga/request", __FILE__)
require File.expand_path("../monga/requests/query", __FILE__)
require File.expand_path("../monga/requests/insert", __FILE__)
require File.expand_path("../monga/requests/delete", __FILE__)
require File.expand_path("../monga/requests/update", __FILE__)
require File.expand_path("../monga/requests/get_more", __FILE__)

module Monga
  extend self

  def logger
    @logger ||= begin
      l = Logger.new(STDOUT)
      l.level = Logger::DEBUG
      l
    end
  end
end
