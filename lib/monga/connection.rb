module Monga
  class Connection
    extend Forwardable

    def_delegators :@connection, :connected?, :responses, :send_command, :is_master?, :port, :primary?, :primary=

    attr_reader :type

    # Simple connection wrapper.
    # Accpets 
    # * host/port or server
    # * connection type
    # * timeout
    def initialize(opts)
      @type = opts[:type]

      host, port = if server = opts[:server]
        h, p = server.split(":")
        [h, p.to_i]
      else
        h = opts[:host] || Monga::DEFAULT_HOST
        p = opts[:port] || Monga::DEFAULT_PORT
        [h, p]
      end
      timeout = opts[:timeout]

      @connection = case @type
      when :em
        require File.expand_path("../connections/em_connection", __FILE__)
        Monga::Connections::EMConnection.connect(host, port, timeout)
      when :sync
        require File.expand_path("../connections/em_connection", __FILE__)
        require File.expand_path("../connections/fibered_connection", __FILE__)
        Monga::Connections::FiberedConnection.connect(host, port, timeout)
      when :block
        require File.expand_path("../connections/kgio_connection", __FILE__)
        Monga::Connections::KGIOConnection.connect(host, port, timeout)
      else
        raise Monga::Exceptions::WrongConnectionType, "Connection type `#{opts[:type]}` is non valid, choose one of: :em, :sync, or :block" unless conn_type
      end
    end
    
    # Returns name of proxy_connection class
    def self.proxy_connection_class(type, client)
      case type
      when :em
        require File.expand_path("../connections/em_proxy_connection", __FILE__)
        Monga::Connections::EMProxyConnection.new(client)
      when :sync
        require File.expand_path("../connections/em_proxy_connection", __FILE__)
        require File.expand_path("../connections/fibered_proxy_connection", __FILE__)
        Monga::Connections::FiberedProxyConnection.new(client)
      when :block
        require File.expand_path("../connections/proxy_connection", __FILE__)
        Monga::Connections::ProxyConnection.new(client)
      end
    end
  end
end