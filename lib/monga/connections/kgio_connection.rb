require 'kgio'
require 'io/nonblock'
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
      @connected = false
      @socket = nil
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
        if size > 4
          length ||= ::BinUtils.get_int32_le(buf)
          torecv = length - size
        end
      end
      @buffer.append(buf)
    end
  end
end