require File.expand_path("../connections/em_connection", __FILE__)
require File.expand_path("../connections/primary", __FILE__)
require File.expand_path("../connections/secondary", __FILE__)

module Monga
  class Connection
    extend Forwardable

    def_delegators :@connection, :connected?, :reconnect, :responses, :send_command, :master?, :is_master?, :host, :port

    CONNECTION_TYPES = {
      default: Monga::Connections::EMConnection,
      primary: Monga::Connections::Primary,
      secondary: Monga::Connections::Secondary,
    }

    def initialize(opts={})
      conn_type = opts.delete(:connection_type) || :default
      conn_class = CONNECTION_TYPES[conn_type]
      @connection = conn_class.connect(opts)
    end
  end
end