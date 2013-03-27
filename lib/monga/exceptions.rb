module Monga::Exceptions
  class LostConnection < StandardError; end
  class CursorNotFound < StandardError; end
  class CursorIsClosed < StandardError; end
  class CursorLimit < StandardError; end
  class QueryFailure < StandardError; end
  class UndefinedIndexVersion < StandardError; end
end