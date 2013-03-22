module Helpers
  module Truncate
    def teardown
      EM.run do
        req = COLLECTION.delete
        EM.add_timer(0.1){ EM.next_tick{ EM.stop } }
      end
    end
  end
end