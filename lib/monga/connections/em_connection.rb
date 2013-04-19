module Monga::Connections
  class EMConnection < EM::Connection
    include EM::Deferrable

    attr_reader :responses

    def initialize(host, port, timeout)
      @host = host
      @port = port
      @timeout = timeout
      @reactor_running = true
      @responses = {}
    end

    def self.connect(host, port, timeout)
      EM.connect(host, port, self, host, port, timeout)
    end

    def send_command(msg, request_id=nil, &cb)
      # Reconnect is a hack for testing.
      # We are stopping EvenMachine for each test.
      # This hack reconnects to Mongo on first query
      reconnect unless @connected

      callback do
        send_data msg
      end
      @responses[request_id] = cb if cb
    end

    def receive_data(data)
      @buffer.append(data)
      @buffer.each do |message|
        request_id = message[2]
        cb = @responses.delete request_id
        cb.call(message) if cb
      end
    end

    def connection_completed
      Monga.logger.debug("Connection is established #{@host}:#{@port}")

      EM.add_shutdown_hook do
        close
      end

      unless @reactor_running
        EM.add_periodic_timer(Monga::Cursor::CLOSE_TIMEOUT){ Monga::Cursor.batch_kill(self) }
      end

      @connected = true
      @pending_for_reconnect = false
      @buffer = Buffer.new
      @reactor_running = true

      succeed
    end

    def reconnect
      unless @connected && @pending_for_reconnect
        if @reactor_running
          super(@host, @port)
        else
          EM.schedule{ super(@host, @port) }
        end
        @pending_for_reconnect = true
      end
    end

    def connected?
      reconnect unless @reactor_running
      @connected || false
    end

    def unbind
      @connected = false
      Monga.logger.debug("Lost connection #{@host}:#{@port}")

      @responses.keys.each do |k|
        cb = @responses.delete k
        err = Monga::Exceptions::Disconnected.new("Disconnected from #{@host}:#{@port}")
        cb.call(err)
      end

      @primary = false
      @pending_for_reconnect = false
      set_deferred_status(nil)

      if @reactor_running
        EM.add_timer(0.1){ reconnect }
      end
    end

    def close
      Monga.logger.debug("EventMachine is stopped, closing connection")
      @reactor_running = false
    end

    def master?
      @primary || false
    end

    def is_master?
      req = Monga::Protocol::Query.new(self, "admin", "$cmd", query: {"isMaster" => 1}, limit: 1)
      command = req.command
      request_id = req.request_id
      @responses[request_id] = proc do |data|
        resp = req.parse_response(data)
        if Exception === resp
          @primary = false
        else
          @primary = resp.last.first["ismaster"]
        end
      end
      send_data command
    end
  end
end