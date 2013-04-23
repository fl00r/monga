module Monga::Connections
  class Buffer
    # include Enumerable

    attr_reader :buffer, :responses

    def initialize
      @buffer = ""
      @position = 0
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
      parse_meta if @position == 0
      parse_doc if @position > 0
    end

    def parse_meta
      return if @buffer_size < 36
      @response = []
      @response << ::BinUtils.get_int32_le(@buffer, @position)
      @response << ::BinUtils.get_int32_le(@buffer, @position += 4)
      @response << ::BinUtils.get_int32_le(@buffer, @position += 4)
      @response << ::BinUtils.get_int32_le(@buffer, @position += 4)
      @response << ::BinUtils.get_int32_le(@buffer, @position += 4)
      @response << ::BinUtils.get_int64_le(@buffer, @position += 4)
      @response << ::BinUtils.get_int32_le(@buffer, @position += 8)
      @response << (@number_returned = ::BinUtils.get_int32_le(@buffer, @position += 4))
      @response << []

      @position += 4
    end

    def parse_doc
      while true
        if @number_returned == 0
          done
          break
        end
        break if @buffer_size < @position + 4
        doc_length = ::BinUtils.get_int32_le(@buffer, @position)
        break if @buffer_size < @position + doc_length
        doc = @buffer[@position, doc_length]
        @response[-1] << CBson.deserialize(doc)
        @position += doc_length
        @number_returned -= 1
        if @number_returned == 0
          done
          break
        end
      end
    end

    def each
      while resp = @responses.shift
        yield resp
      end
    end

    def done
      @responses << @response
      @response = nil
      if @buffer_size == @position
        @buffer.clear
      else
        @buffer = @buffer[@position, @buffer_size-@position]
      end
      @buffer_size = @buffer.bytesize
      @position = 0
    end
  end
end