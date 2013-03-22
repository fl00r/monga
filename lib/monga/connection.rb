module Monga
  DEFAULT_HOST = "127.0.0.1"
  DEFAULT_PORT = 27017
  HEADER_SIZE  = 16
  
  class Connection < EM::Connection
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

    def initialize(opts = {})
      @host = opts[:host]
      @port = opts[:port]
      @responses = {}
    end

    def [](db_name)
      Monga::Database.new(self, db_name)
    end

    def self.connect(opts = {})
      host = opts[:host] || DEFAULT_HOST
      port = opts[:port] || DEFAULT_PORT

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
      # Gracefully close connection when EventMachine stop
      EM.add_shutdown_hook do
        Monga.logger.debug("EventMachine is stopped, closing connection")
        close
      end

      @connected = true
      @reactor_running = true
      @pending_for_reconnect = false
      @buffer = Buffer.new

      succeed
    end

    def reconnect
      unless @pending_for_reconnect || connected?
        EM.schedule{ super(@host, @port) }
        @pending_for_reconnect = true
      end
    end

    def connected?
      @connected || false
    end

    def unbind
      @responses.each{ |k, cb| cb.call(LostConnection.new("Mongo has lost connection"))}
      @connected = false
      set_deferred_status(nil)

      if @reactor_running
        EM.add_timer(0.01){ reconnect }
      end
    end

    def close
      @reactor_running = false
    end
  end
end