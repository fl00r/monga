module Monga
  class Client
    extend Forwardable

    def_delegators :@client, :aquire_connection

    VALID_OPTS = [:host, :port, :server, :type, :pool_size, :servers, :read_pref, :timeout]

    # Following options are allowed
    # * host - host of server to connect, default 127.0.0.1
    # * port - port of server to connect, default 27017
    # * server - host:port of server to connect (you can pass server or host/port pair)
    # * type - :em/:sync/:block - socket type, asynchronouse on EventMachine, Fibered or blocking TCP
    # * pool_size - connection pool size
    # * servers - array of server names (host:port) to connect or array of hashes host/port (for Replica Set connection)
    # * read_pref - read preference for Replica Set (:primary, :secondary, :primary_preferred, :secondary_preferred), default :primary
    # * timeout - client will try to reconnect till timout (in seconds) if connection failed, default 10 seconds
    def initialize(opts = {})
      @opts = opts
      @opts[:type] ||= :block

      sanitize_opts!
      create_client
    end

    # Choose database by it's name
    def get_database(db_name)
      Monga::Database.new(@client, db_name)
    end
    alias :[] :get_database

    private

    # Validates incoming options to prevent missunderstanding
    def sanitize_opts!
      @opts.each_key do |key|
        unless VALID_OPTS.include? key
          raise Monga::Exceptions::InvalidClientOption, "`#{key}` is invalid option for Client. Following options are valid: #{VALID_OPTS * ', '}"
        end
      end
    end

    # If servers options is defined it will create ReplicaSetClient,
    # otherwise SingleInstanceClient will be created
    def create_client
      @client = if @opts[:servers]
        Monga::Clients::ReplicaSetClient.new(@opts)
      else
        Monga::Clients::SingleInstanceClient.new(@opts)
      end
    end
  end
end