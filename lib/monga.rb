require "eventmachine"
require "bson"
require "logger"

require "monga/connection"
require "monga/collection"
require "monga/cursor"
require "monga/exceptions"
require "monga/response"
require "monga/request"
require "monga/requests/query"

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
