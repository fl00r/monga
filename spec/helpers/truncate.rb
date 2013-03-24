module Helpers
  module Truncate
    def teardown
      EM.run do
        req = COLLECTION.safe_delete
        req.callback{ |res| EM.stop }
        req.errback{ |err| raise err }
      end
    end
  end
end