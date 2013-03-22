module Monga::Exceptions
  class LostConnection < StandardError; end
  class CursorNotFound < StandardError; end
  class QueryFailure < StandardError; end
  class UndefinedIndexVersion < StandardError; end
end