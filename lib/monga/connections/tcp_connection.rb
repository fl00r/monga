require 'socket'

# Currently blocking mode is very poor.
# It is working as is.
# Going to support reconnecting and timouts later.
# Use it for tests and prototyping. Not the best choice for production.

module Monga::Connections
  class TCPConnection
    def self.connect(host, port, timeout)
      new(host, port, timeout)
    end

    def initialize(host, port, timeout)
      @host, @port, @timout = host, port, timeout
      @connected = true
      @buffer = Buffer.new
      socket
    end

    def connected?
      @connected
    end

    def socket
      @socket ||= TCPSocket.new(@host, @port)
    end

    # Fake answer, as far as we are blocking
    def responses
      0
    end

    def send_command(msg, request_id=nil, &cb)
      socket.send msg.to_s, 0
      if cb
        length = socket.read(4)
        @buffer.append(length)
        l = length.unpack("L").first
        rest = socket.read(l-4)
        @buffer.append(rest)
        @buffer.each do |message|
          rid = message[2]
          fail "Returned Request Id is not equal to sended one" if rid != request_id
          cb.call(message)
        end
      end
    rescue Errno::EPIPE => e
      @socket = nil
      err = Monga::Exceptions::Disconnected.new("Disconnected from #{@host}:#{@port}")
      cb.call(err)
    end
  end
end