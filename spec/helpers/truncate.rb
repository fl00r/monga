module Helpers
  module Truncate
    def teardown
      EM.run do
        RS_COLLECTION.safe_delete.callback do
          RS_COLLECTION.drop_indexes.callback do
            COLLECTION.safe_delete.callback do |res|
              COLLECTION.drop_indexes.callback{ EM.stop }
            end
          end
        end
      end
    end
  end
end