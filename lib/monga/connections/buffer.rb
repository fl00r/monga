module Monga::Connections
  class Buffer
    include Enumerable

    attr_reader :buffer, :responses

    def initialize
      @buffer = ""
      @position = 0
      @number_unpacked = 0
      @docs = []
      @responses = []
    end

    def append(data)
      @buffer << data
      @buffer_size = @buffer.bytesize
      job
      @buffer
    end

    def job
      begin
        cont = false
        parse_meta unless @response
        cont = parse_doc if @position > 0
      end while cont
    end

    def parse_meta
      return if @buffer_size < 36
      meta = @buffer[0, 36]
      msg_length = BinUtils.get_int32_le(meta, @position)
      request_id = BinUtils.get_int32_le(meta, @position += 4)
      response_to = BinUtils.get_int32_le(meta, @position += 4)
      op_code = BinUtils.get_int32_le(meta, @position += 4)
      flags = BinUtils.get_int32_le(meta, @position += 4)
      cursor_id = BinUtils.get_int64_le(meta, @position += 4)
      starting_from = BinUtils.get_int32_le(meta, @position += 8)
      @number_returned = BinUtils.get_int32_le(meta, @position += 4)

      @position += 4

      @response = [msg_length, request_id, response_to, op_code, flags, cursor_id, starting_from, @number_returned, []]
    end

    def parse_doc
      if @number_returned == 0
        done
        return true
      end
      return if @buffer_size < @position + 4
      doc_length = BinUtils.get_int32_le(@buffer, @position)
      return if @buffer_size < @position + doc_length
      doc = @buffer[@position, doc_length]
      @response.last << BSON::BSON_CODER.deserialize(doc)
      @position += doc_length
      @number_unpacked += 1
      if @number_unpacked == @number_returned
        done
      end
      return true
    end

    def each
      while resp = @responses.shift
        yield resp
      end
    end

    def done
      @responses << @response
      @response = nil
      @buffer.slice!(0, @position)
      @buffer_size = @buffer.bytesize
      @position = 0
      @number_returned = @number_unpacked = 0
    end
  end
end