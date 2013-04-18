module Monga
  class Connection
    extend Forwardable

    def_delegators :@connection, :connected?, :responses, :send_command

    CONNECTIONS = {
      em: Monga::Connections::EMConnection,
      sync: Monga::Connections::FiberedConnection,
      block: Monga::Connections::TCPConnection,
    }
    PROXY_CONNECTIONS = {
      em: Monga::Connections::EMProxyConnection,
      sync: Monga::Connections::EMProxyConnection,
      block: Monga::Connections::ProxyConnection,
    }

    # Simple connection wrapper.
    # Accpets 
    # * host/port or server
    # * connection type
    # * timeout
    def initialize(opts)
      host, port = if server = opts[:server]
        h, p = server.split(":")
        [h, p.to_i]
      else
        h = opts[:host] || Monga::DEFAULT_HOST
        p = opts[:port] || Monga::DEFAULT_PORT
        [h, p]
      end
      timeout = opts[:timeout]

      conn_type = CONNECTIONS[opts[:type]]
      raise Monga::Exceptions::WrongConnectionType, "Connection type `#{opts[:type]}` is non valid, choose one of: :em, :sync, or :block" unless conn_type
      @connection = conn_type.connect(host, port, timeout)
    end

    # Returns name of proxy_connection class
    def self.proxy_connection_class(type)
      PROXY_CONNECTIONS[type]
    end
  end
end