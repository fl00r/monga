module Monga::Connections
  class Primary < Monga::Connections::EMConnection
    def initialize(opts)
      @client = opts.delete :client
      super
    end

    def connection_completed
      check_master do |master|
        @client.inform(:primary, @host, @port)
        super()
      end
    end
  end
end