module Monga
  class Request
    OP_CODES = {
      reply:          1,
      msg:         1000,
      update:      2001,
      insert:      2002,
      reserved:    2003,
      query:       2004,
      get_more:    2005,
      delete:      2006,
      kill_cursor: 2007,
    }

    def initialize(collection, options = {})
      @collection = collection
      @options = options
      @request_id = self.class.request_id
    end

    def command
      header.append!(body)
    end

    def header
      headers = BSON::ByteBuffer.new
      headers.put_int(command_length)
      headers.put_int(@request_id)
      headers.put_int(0)
      headers.put_int(op_code)
      headers
    end

    # Fire and Forget
    def perform
      @collection.connection.send_command(command)
      @request_id
    end

    # Fire and wait
    def calback_perform
      response = Monga::Response.new
      @collection.connection.send_command(command, @request_id) do |resp|
        response.succeed(resp)
      end
      response
    end

    # Fire, forget, check
    def safe_perform
      # TODO
    end

    private

    def op_code
      OP_CODES[self.class.op_name]
    end

    def command_length
      HEADER_SIZE + body.size
    end

    def self.request_id
      @request_id ||= 0
      @request_id += 1
    end

    def self.op_name(op = nil)
      op ? @op_name = op : @op_name
    end
  end
end