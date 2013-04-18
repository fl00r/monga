require 'socket'

module Monga::Connections
  class TCPConnection
    def self.connect(host, port, timeout)
      new(host, port, timeout)
    end

    def initialize(host, port, timeout)
      @host, @port, @timout = host, port, timeout
      @socket ||= TCPSocket.new(@host, @port)
      @connected = true
      @buffer = Buffer.new
    end

    def connected?
      @connected
    end

    # Fake answer, as far as we are blocking
    def responses
      0
    end

    def send_command(msg, request_id=nil, &cb)
      @socket.send msg.to_s, 0
      if cb
        length = @socket.read(4)
        @buffer.append(length)
        l = length.unpack("L").first
        rest = @socket.read(l-4)
        @buffer.append(rest)
        @buffer.each do |message|
          rid = message[2]
          fail "Returned Request Id is not equal to sended one" if rid != request_id
          cb.call(message)
        end
      end
    end
  end
end