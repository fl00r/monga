module Monga::Connections
  class Buffer
    include Enumerable
    EMPTY = ""

    attr_reader :buffer, :buffer_size

    def initialize
      @buffer = ""
      @position = 0
      @buffer_size = 0
      @response = []
    end

    def append(data)
      @buffer << data
      @buffer_size += data.bytesize
    end

    def each
      while doc = parse_buffer
        yield doc
      end
    end

    def parse_buffer
      return if @buffer_size == 0

      if @position == 0
        parse_doc if parse_meta
      else
        parse_doc 
      end

      if @number_returned == 0
        if @buffer_size == @position
          @buffer.clear
          @buffer_size = 0
        else
          @buffer = @buffer[@position, @buffer_size-@position]
          @buffer_size -= @position
        end
        @position = 0

        @response  unless @response.empty?
      end
    end

    def parse_meta
      @response.clear
      return  if @buffer_size < 36
      @response << ::BinUtils.get_int32_le(@buffer, @position)
      @response << ::BinUtils.get_int32_le(@buffer, @position += 4)
      @response << ::BinUtils.get_int32_le(@buffer, @position += 4)
      @response << ::BinUtils.get_int32_le(@buffer, @position += 4)
      @response << ::BinUtils.get_int32_le(@buffer, @position += 4)
      @response << ::BinUtils.get_int64_le(@buffer, @position += 4)
      @response << ::BinUtils.get_int32_le(@buffer, @position += 8)
      @number_returned = ::BinUtils.get_int32_le(@buffer, @position += 4)
      @response << @number_returned
      @position += 4
      @response << []

    end

    def parse_doc
      @str_io = nil  if @number_returned == @response[7]

      current_pos = @position
      while @number_returned > 0
        doc_length = ::BinUtils.get_int32_le(@buffer, @position)
        break if @buffer_size - @position < doc_length
        @number_returned -= 1
        @position += doc_length
      end

      if @str_io
        @str_io << @buffer[current_pos..@position]
      else
        @str_io = StringIO.new @buffer[current_pos..@position]
      end

      if @number_returned == 0
        @str_io.rewind
        @response[7].times do
          @response[-1] << BSON::Document.from_bson(@str_io)
        end
      end
    end
  end
end