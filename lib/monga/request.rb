module Monga
  class Request
    attr_reader :request_id, :connection

    OP_CODES = {
      reply:           1,
      msg:          1000,
      update:       2001,
      insert:       2002,
      reserved:     2003,
      query:        2004,
      get_more:     2005,
      delete:       2006,
      kill_cursors: 2007,
    }

    def initialize(connection, db_name, collection_name, options = {})
      @connection = connection
      @db_name = db_name
      @collection_name = collection_name
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
      @connection.send_command(command, @request_id)
      self
    end

    # Fire and wait
    def callback_perform
      @connection.send_command(command, @request_id) do |data|
        err, resp = parse_response(data)
        if block_given?
          yield(err, resp)
        else
          err ? raise(err) : resp
        end
      end
    end

    def parse_response(data)
      if Exception === data
        [data, nil]
      else
        flags = data[4]
        number = data[7]
        docs = unpack_docs(data.last, number)
        data[-1] = docs
        if flags & 2**0 > 0
          Monga::Exceptions::CursorNotFound.new(docs.first)
        elsif flags & 2**1 > 0
          Monga::Exceptions::QueryFailure.new(docs.first)
        elsif docs.first && (docs.first["err"] || docs.first["errmsg"])
          Monga::Exceptions::QueryFailure.new(docs.first)
        else
          [nil, data]
        end
      end
    end

    private

    def unpack_docs(data, number)
      number.times.map do
        size = data.slice(0, 4).unpack("L").first
        d = data.slice!(0, size)
        BSON.deserialize(d)
      end
    end

    def flags
      flags = 0
      self.class::FLAGS.each do |k, byte|
        flags = flags | 1 << byte if @options[k]
      end
      flags
    end

    def full_name
      [@db_name, @collection_name] * "."
    end

    def op_code
      OP_CODES[self.class.op_name]
    end

    def command_length
      Monga::HEADER_SIZE + body.size
    end

    def self.request_id
      @@request_id ||= 0
      @@request_id += 1
      @@request_id >= 2**32 ? @@request_id = 1 : @@request_id
    end

    def self.op_name(op = nil)
      op ? @op_name = op : @op_name
    end
  end
end


require File.expand_path("../protocol/query", __FILE__)
require File.expand_path("../protocol/insert", __FILE__)
require File.expand_path("../protocol/delete", __FILE__)
require File.expand_path("../protocol/update", __FILE__)
require File.expand_path("../protocol/get_more", __FILE__)
require File.expand_path("../protocol/kill_cursors", __FILE__)