module Helpers
  module Truncate
    def teardown
      EM.run do
        req = COLLECTION.drop
        req.callback do |res|
          EM.stop
        end
        req.errback{ |err| p "!!!!"*100; raise err }
      end
    end
  end
end