module Helpers
  module Truncate
    def teardown
      EM.run do
        # req = COLLECTION.safe_delete
        # req.callback{ |res| EM.stop }
        # req.errback{ |err| raise err }
        EM.stop
      end
    end
  end
end