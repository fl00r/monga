module Helpers
  module Truncate
    def teardown
      EM.run do
        req = COLLECTION.safe_delete
        req.callback do |res|
          req = COLLECTION.drop_indexes
          req.callback{ EM.stop }
          req.errback{ |err| raise err }
        end
        req.errback{ |err| raise err }
      end
    end
  end
end