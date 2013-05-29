require 'eventmachine'

module Fake
  # Fake Response.
  # It could be `ok`, or `primary?` reply.
  class Response
    def initialize(data, primary)
      @data = data
      @primary = primary
    end

    def ok(doc = nil)
      document = doc || { ok: 1.0 }
      [flags, cursor_id, starting_from, number_returned].pack("LQLL")
      b = ::BinUtils.append_int32_le!(nil, flags)
      ::BinUtils.append_int64_le!(b, cursor_id)
      ::BinUtils.append_int32_le!(b, starting_from, number_returned)
      b << document.to_bson

      header(b) + b.to_s
    end

    def primary?
      doc = { ismaster: @primary }
      ok(doc)
    end

    private

    def header(body)
      length = 16 + body.to_s.bytesize
      request_id = 0
      op_code = 0

      h = ::BinUtils.append_int32_le!(nil, flags, request_id, response_to, op_code)
    end

    def response_to
      @data.unpack("LLLL")[1]
    end

    def flags; 0; end
    def cursor_id; 0; end
    def starting_from; 0; end
    def number_returned; 1; end
  end

  # Fake MongoDB server.
  # Replies with `ok` message for all 2004 op queries instead `isMaster`.
  # For other ops it sends no answer.
  class Node < EM::Connection
    def initialize(si)
      @si = si
      @si.server = self
    end

    def primary
      @si.rs.primary == @si  if @si.rs
    end

    def receive_data(data)
      begin
        length, req_id, resp_to, op_code = data.unpack("LLLL")
        piece = data.slice!(0, length)
        if op_code == 2004
          if piece["isMaster"]
            send_data Fake::Response.new(piece, primary).primary?
          else
            send_data Fake::Response.new(piece, primary).ok
          end
        end
      end while data != ""
    end
  end

  # Single instance binded on one port.
  # Could be stopped or started.
  class SingleInstance
    attr_reader :rs, :port
    attr_accessor :server

    def initialize(port, rs=nil)
      @rs = rs
      @port = port
      EM.add_shutdown_hook{ @connected = false }
    end

    def start
      @sign = EM.start_server('127.0.0.1', @port, Fake::Node, self)  unless @connected
      @connected = true
    end

    def stop
      @server.close_connection  if @server
      EM.stop_server @sign
      @connected = false
    end

    def connected?
      @connected
    end
  end

  # Fake Replica set with a number of Single Instances.
  # You could stop/start primary/secondary.
  class ReplicaSet
    def initialize(ports)
      @instances = ports.map do |port|
        SingleInstance.new(port, self)
      end
    end

    def start_all
      @instances.each(&:start)
    end

    def vote
      @primary = @instances.select{|inst| inst.connected? }.sample
      @primary
    end

    def primary
      @primary ||= begin
        @instances.select{|inst| inst.connected? }.sample
      end
    end

    def secondaries
      @instances - [@primary]
    end
  end
end