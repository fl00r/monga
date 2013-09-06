module Monga
  class Request
    attr_reader :request_id, :collection, :connection

    # FLAGS = {}
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

    def initialize(request_opts, options = {})
      @connection = request_opts[:connection]
      @client = request_opts[:client]
      @db_name = request_opts[:db_name]
      @collection_name = request_opts[:collection_name]
      @options = options

      # check_flags
      @request_id = self.class.request_id
    end

    def command
      header + body
    end

    def header
      ::BinUtils.append_int32_le!(nil, command_length, @request_id, 0, op_code)
    end

    # Fire and Forget
    def perform(&blk)
      aquire_connection do |connection|
        connection.send_command(command, @request_id)
        blk.call(self)  if block_given?
      end
    end

    # Fire and wait
    def callback_perform(&blk)
      aquire_connection do |connection|
        connection.send_command(command, @request_id) do |data|
          err, resp = parse_response(data)
          blk.call(self, err, resp)
        end
      end
    end

    def parse_response(data)
      if Exception === data
        [data, nil]
      else
        flags = data[4]
        docs = data.last
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

    def aquire_connection
      if @connection
        yield @connection
      else
        @client.aquire_connection do |connection|
          @connection = connection
          yield connection
        end
      end
    end

    # Ouch!
    def check_flags
      return  unless @options[:query]
      self.class::FLAGS.each do |k, byte|
        v = @options[:query].delete(k)
        @options[k] = v  if v
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
      @@request_id
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