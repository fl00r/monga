require 'kgio'

# Toy blocking connection over TCP
module Monga::Connections
  class KGIOConnection
    TO_RECV = 512

    attr_writer :primary

    def self.connect(host, port, timeout)
      new(host, port, timeout)
    end

    def initialize(host, port, timeout)
      @host, @port, @timout = host, port, timeout
      @connected = true
      @buffer = Buffer.new
      @tmp = ""
    end

    def connected?
      socket unless @connected
      @connected
    end

    def socket
      @socket ||= begin
        sock = Kgio::TCPSocket.new(@host, @port)
        # MacOS doesn't support autopush
        sock.kgio_autopush = true unless RUBY_PLATFORM['darwin']
        # check connection
        sock.kgio_write ""
        @connected = true
        sock
      end
    rescue => e
      Monga.logger.error e.message
      nil
    end

    # Fake answer, as far as we are blocking,
    # but we should support API
    def responses
      0
    end

    def send_command(msg, request_id=nil, &cb)
      raise Errno::ECONNREFUSED, "Connection Refused" unless socket
      socket.kgio_write msg
      if cb
        read_socket

        message = @buffer.first
        rid = message[2]

        fail "Returned Request Id is not equal to sended one (#{rid} != #{request_id}), #{message}" if rid != request_id

        cb.call(message)
      end
    rescue Errno::ECONNREFUSED, Errno::EPIPE => e
      close
      if cb
        err = Monga::Exceptions::Disconnected.new("Disconnected from #{@host}:#{@port}, #{e.message}")
        cb.call(err)
      end
    end

    def read_socket
      while @buffer.buffer_size < 4
        unless socket.kgio_read(TO_RECV, @tmp)
          raise Errno::ECONNREFUSED.new "Nil was return. Closing connection"
        end

        @buffer.append(@tmp)

        size = @buffer.buffer_size
        if size >= 4
          length = ::BinUtils.get_int32_le(@buffer.buffer)  

          torecv = length - size
          if torecv > 0
            socket.read(torecv, @tmp)
            @buffer.append(@tmp)
          end
        end
      end
    end

    def primary?
      @primary || false
    end

    def is_master?
      req = Monga::Protocol::Query.new(self, "admin", "$cmd", query: {"isMaster" => 1}, limit: 1)
      command = req.command
      request_id = req.request_id
      socket.kgio_write command
      read_socket
      message = @buffer.first
      @primary = message.last.first["ismaster"]
      yield @primary ? :primary : :secondary
    rescue => e
      Monga.logger.error e.message
      close
      yield nil
    end

    def close
      @socket = nil
      @primary = false
      @connected = false
    end
  end
end