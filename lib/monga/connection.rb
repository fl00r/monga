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
      host = opts[:host]
      port = opts[:port]
      @responses = {}
    end

    def [](collection_name)
      Monga::Collection.new(self, collection_name)
    end

    def self.connect(opts = {})
      host = opts[:host] || DEFAULT_HOST
      port = opts[:port] || DEFAULT_PORT

      EM.connect(host, port, self, opts)
    end

    def send_command(msg, request_id, &cb)
      callback do
        send_data msg
      end

      @responses[request_id] = cb if block_given?
    end

    def receive_data(data)
      @buffer.append(data)
      @buffer.each do |message|
        request_id = message[2]
        @responses[request_id].call(message)
      end
    end

    def connection_completed
      # Gracefully close connection when EventMachine stop
      EM.add_shutdown_hook do
        Monga.logger.debug("EventMachine is stopped, closing connection")
        close
      end

      @connected = true
      @buffer = Buffer.new

      succeed
    end

    def connected?
      @connected || false
    end

    def unbind
      unless @closed
        @closed = true
        raise Monga::Exceptions::LostConnection, "Connection to MongoDB lost"
      end
    end

    def close
      unless @closed
        @closed = true
      end
    end
  end
end