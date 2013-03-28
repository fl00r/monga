require File.expand_path("../connections/em_connection", __FILE__)
require File.expand_path("../connections/primary", __FILE__)
require File.expand_path("../connections/secondary", __FILE__)

module Monga
  class Connection
    CONNECTION_TYPES = {
      default: Monga::Connections::EMConnection,
      primary: Monga::Connections::Primary,
      secondary: Monga::Connections::Secondary,
    }

    def initialize(opts={})
      conn_type = opts.delete(:type) || :default
      conn_class = CONNECTION_TYPES[conn_type]
      @connection = conn_class.connect(opts)
    end

    def send_command(msg, request_id=nil, &cb)
      aquire_connection.send_command(msg, request_id, &cb)
    end

    def aquire_connection
      @connection
    end

    def responses
      @connection.responses
    end
  end
end