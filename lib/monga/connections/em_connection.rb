module Monga::Connections
  class EMConnection < EM::Connection
    include EM::Deferrable

    class Buffer
      include Enumerable

      attr_reader :buffer

      def initialize
        @buffer = ""
        @positon = 0
      end

      def append(data)
        @buffer += data
      end

      def each
        while true
          size = @buffer.size
          if size > Monga::HEADER_SIZE
            msg_length = @buffer[0, 4].unpack("L").first
            if msg_length && size >= msg_length
              data = @buffer.slice!(0, msg_length)
              yield data.unpack("LLLLLQLLa*")
            else
              break
            end
          else
            break
          end
        end
      end
    end

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

    def force_reconnect(host, port)
      @connected = false
      @host = host
      @port = port
    end

    def connected?
      EM.schedule { reconnect } unless @reactor_running
      @connected || false
    end

    def unbind
      Monga.logger.debug("Lost connection #{@host}:#{@port}")

      @responses.each{ |k, cb| cb.call(Monga::Exceptions::Disconnected.new("Disconnected from #{@host}:#{@port}"))}
      @primary = false
      @pending_for_reconnect = false
      set_deferred_status(nil)

      if @reactor_running && @timeout
        unless @pending_timeout
          @pending_timeout = true
          EM.add_timer(@timeout) do
            unless @connected
              raise Monga::Exceptions::CouldNotReconnect, "Could not reconnect to #{@host}:#{@port}"
            end
            @pending_timeout = false
          end
        end
        EM.add_timer(0.1){ reconnect }
      elsif @reactor_running
        if @connected
          raise Monga::Exceptions::Disconnected, "Disconnected from #{@host}:#{@port}"
        else
          raise Monga::Exceptions::CouldNotConnect, "Could not connect to #{@host}:#{@port}"
        end
      end
      @connected = false
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