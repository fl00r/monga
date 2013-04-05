module Monga
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

    attr_reader :responses, :host, :port

    def initialize(opts = {})
      @host = opts[:host]
      @port = opts[:port]
      @reactor_running = true
      @responses = {}
    end

    def self.connect(opts = {})
      host = opts[:host] ||= Monga::DEFAULT_HOST
      port = opts[:port] ||= Monga::DEFAULT_PORT

      EM.connect(host, port, self, opts)
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

      @responses.each{ |k, cb| cb.call(Monga::Exceptions::LostConnection.new("Mongo has lost connection"))}
      @connected = false
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

    def is_master?(client)
      db = client["admin"]
      req = Monga::Requests::Query.new(db, "$cmd", query: {"isMaster" => 1}, limit: 1)
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

  class Connection
    extend Forwardable

    def_delegators :@connection, :connected?, :reconnect, :responses, :send_command, :master?, :is_master?, :host, :port

    def initialize(opts={})
      @connection = Monga::EMConnection.connect(opts)
    end
  end
end