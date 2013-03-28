module Monga::Connections
  class Secondary < Monga::Connections::EMConnection
    def initialize(opts)
      @client = opts.delete :client
      super
    end

    def connection_completed
      @client.inform(:secondary, @host, @port)
      super()
    end
  end
end