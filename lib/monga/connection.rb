module Monga
  DEFAULT_HOST = "127.0.0.1"
  DEFAULT_PORT = 27017
  HEADER_SIZE  = 16
  
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
          if size > HEADER_SIZE
            msg_length = @buffer[0, 4].unpack("L").first
            if msg_length && size >= msg_length
              data = @buffer.slice!(0, size)
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

    def initialize(opts = {})
      @host = opts[:host]
      @port = opts[:port]
      @reactor_running = true
      @responses = {}
    end

    def self.connect(opts = {})
      host = opts[:host] ||= DEFAULT_HOST
      port = opts[:port] ||= DEFAULT_PORT

      EM.connect(host, port, self, opts)
    end

    def send_command(msg, request_id=nil, &cb)
      reconnect unless @reactor_running

      callback do
        send_data msg
      end

      @responses[request_id] = cb if block_given?
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
      Monga.logger.debug("Connection is established")

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
      unless connected?
        if @reactor_running
          super(@host, @port)
        else
          unless @pending_for_reconnect
            EM.schedule{ super(@host, @port) }
            @pending_for_reconnect = true
          end
        end
      end
    end

    def connected?
      @connected || false
    end

    def unbind
      Monga.logger.debug("Lost connection")

      @responses.each{ |k, cb| cb.call(Monga::Exceptions::LostConnection.new("Mongo has lost connection"))}
      @connected = false
      set_deferred_status(nil)

      if @reactor_running
        EM.add_timer(0.01){ reconnect }
      end
    end

    def close
      Monga.logger.debug("EventMachine is stopped, closing connection")
      @reactor_running = false
    end
  end

  class Connection
    def initialize(opts={})
      @connection = EMConnection.connect(opts)
    end

    def send_command(msg, request_id=nil, &cb)
      aquire_connection.send_command(msg, request_id, &cb)
    end

    def [](db_name)
      Monga::Database.new(self, db_name)
    end

    def aquire_connection
      @connection
    end

    def responses
      @connection.responses
    end
  end
end