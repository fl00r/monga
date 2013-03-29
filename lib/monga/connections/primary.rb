module Monga::Connections
  class Primary < Monga::Connections::EMConnection
    def initialize(opts)
      @client = opts.delete :client
      @ser
      super
    end

    def connection_completed
      check_master do |master|
        if master
          super
        else
          reconnect
        end
      end
    end

    def check_master
      db = @client["admin"]
      request = Monga::Request.new(db, "$cmd", query: { "isMaster" => 1 })
      request_id = request.request_id
      @responses[request_id] = proc do |data|
        request.parse_response(data)
        if Exception === data
          Monga.logger.debug("Error on connecting Primary to #{@host}:#{@port}, #{data.class}, #{data.message}")
          @host, @port = @client.next_addr(@host, @port)
          yield false
        else
          doc = data.last.first
          if doc["ismaster"]
            Monga.logger.debug("Primary has connected to #{@host}:#{@port}")
            @client.inform(:primary, @host, @port)
            yield true
          else
            Monga.logger.debug("#{@host}:#{@port} is not a primary")
            @host, @port = @client.select_addr(doc)
            yield false
          end
        end
      end
      command = request.command
      send_data(command)
    end
  end
end