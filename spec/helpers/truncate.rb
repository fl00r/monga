module Helpers
  module Truncate
    def teardown
      EM.run do
        req = COLLECTION.drop
        req.callback do |res|
          EM.stop
        end
        req.errback{ |err| raise err }
      end
    end
  end
end