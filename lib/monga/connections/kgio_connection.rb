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
        read_socket(1024)
        @buffer.each do |message|
          rid = message[2]
          fail "Returned Request Id is not equal to sended one (#{rid} != #{request_id}), #{message}" if rid != request_id
          cb.call(message)
        end
      end
    rescue Errno::ECONNREFUSED, Errno::EPIPE => e
      @connected = false
      @socket = nil
      if cb
        err = Monga::Exceptions::Disconnected.new("Disconnected from #{@host}:#{@port}, #{e.message}")
        cb.call(err)
      end
    end

    def read_socket(bytes)
      torecv = nil
      while !torecv || torecv > 0
        resp = socket.kgio_read(torecv || bytes)
        raise Errno::ECONNREFUSED.new "Nil was return. Closing connection" unless resp
        @buffer.append(resp)
        size = resp.bytesize
        if !torecv && size > 4
          length = BinUtils.get_int32_le(resp)
          torecv = length - size
        elsif torecv
          torecv -= size
        end
      end
    end
  end
end