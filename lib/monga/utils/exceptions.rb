module Monga::Exceptions
  class InvalidClientOption < StandardError; end
  class UndefinedSocketType < StandardError; end
  class WrongConnectionType < StandardError; end
  class Disconnected < StandardError; end
  class CouldNotConnect < StandardError; end
  class CouldNotReconnect < StandardError; end
  class QueryFailure < StandardError; end
  class CursorNotFound < StandardError; end
  class ClosedCursor < StandardError; end
end