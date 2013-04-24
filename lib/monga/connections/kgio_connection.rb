require 'kgio'
require 'io/nonblock' # ha?
module Monga::Connections
  class KGIOConnection
    def self.connect(host, port, timeout)
      new(host, port, timeout)
    end

    def initialize(host, port, timeout)
      @host, @port, @timout = host, port, timeout
      @connected = true
      @buffer = Buffer.new
    end

    def connected?
      @connected
    end

    def socket
      @socket ||= begin
        sock = Kgio::TCPSocket.new(@host, @port)
        sock.kgio_autopush = true
        @connected = true
        sock
      end
    end

    # Fake answer, as far as we are blocking
    def responses
      0
    end

    def send_command(msg, request_id=nil, &cb)
      socket.kgio_write msg.to_s
      if cb
        read_socket

        message = @buffer.responses.shift
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
      torecv = 512
      length = nil
      buf = ''.force_encoding('ASCII-8BIT')
      tmp = ''
      while torecv > 0
        resp = socket.kgio_read(torecv, tmp)
        raise Errno::ECONNREFUSED.new "Nil was return. Closing connection" unless resp
        buf << resp
        size = buf.bytesize
        length ||= ::BinUtils.get_int32_le(buf) if size > 4
        torecv = length - size if length
      end
      @buffer.append(buf)
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
      message = @buffer.responses.shift
      @primary = message.last.first["ismaster"]
      yield @primary ? :primary : :secondary
    rescue => e
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