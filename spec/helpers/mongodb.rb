module Fake
  class Response
    def initialize(data)
      @data = data
    end

    def simple
      flags = 0
      cursor_id = 0
      starting_from = 0
      number_returned = 1
      document = { ok: true }
      [flags, cursor_id, starting_from, number_returned].pack("LQLL")
      b = BSON::ByteBuffer.new
      b.put_int(flags)
      b.put_long(cursor_id)
      b.put_int(starting_from)
      b.put_int(number_returned)
      b.append!(BSON::BSON_C.serialize(document).to_s)

      header(b) + b.to_s
    end

    def primary
      
    end

    def secondary
      
    end

    private

    def header(body)
      length = 16 + body.to_s.bytesize
      request_id = 0
      op_code = 0

      h = BSON::ByteBuffer.new
      h.put_int(length)
      h.put_int(request_id)
      h.put_int(response_to)
      h.put_int(op_code)
      h.to_s
    end

    def response_to
      @data.unpack("LLLL")[1]
    end
  end

  class Instance < EM::Connection
    def initialize
      
    end

    def receive_data(data)
      begin
        length, req_id, resp_to, op_code = data.unpack("LLLL")
        piece = data.slice!(0, length)
        if op_code == 2004
          if data["master"]
            send_data Fake::Response.new(piece).primary?
          else
            send_data Fake::Response.new(piece).simple
          end
        end
      end while data != ""
    end
  end

  class MongodbInstance
    def initialize(port)
      @port = port
    end

    def start
      @sign = EM.start_server '127.0.0.1', @port, Fake::Instance do |serv|
        @server = serv
      end
    end

    def stop
      @server.close_connection
      EM.stop_server @sign
    end
  end
end