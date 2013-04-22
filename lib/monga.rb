require "em-synchrony"
require "bson"
require "logger"
require "forwardable"

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

# It is strange, but cursor should be required befor fibered_connection
require File.expand_path("../monga/cursor", __FILE__)

require File.expand_path("../monga/clients/single_instance_client", __FILE__)
require File.expand_path("../monga/clients/replica_set_client", __FILE__)
require File.expand_path("../monga/connections/em_connection", __FILE__)
require File.expand_path("../monga/connections/fibered_connection", __FILE__)
require File.expand_path("../monga/connections/tcp_connection", __FILE__)
require File.expand_path("../monga/connections/em_proxy_connection", __FILE__)
require File.expand_path("../monga/connections/fibered_proxy_connection", __FILE__)
require File.expand_path("../monga/connections/proxy_connection", __FILE__)
require File.expand_path("../monga/connections/buffer", __FILE__)

require File.expand_path("../monga/client", __FILE__)
require File.expand_path("../monga/connection", __FILE__)
require File.expand_path("../monga/connection_pool", __FILE__)
require File.expand_path("../monga/database", __FILE__)
require File.expand_path("../monga/collection", __FILE__)
require File.expand_path("../monga/request", __FILE__)
require File.expand_path("../monga/utils/exceptions", __FILE__)
require File.expand_path("../monga/utils/constants", __FILE__)