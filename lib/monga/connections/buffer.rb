module Monga::Connections
  class Buffer
    include Enumerable

    attr_reader :buffer

    def initialize
      @buffer = ""
      @positon = 0
    end

    def append(data)
      @buffer += data
    end

    def each
      while true
        size = @buffer.size
        if size > Monga::HEADER_SIZE
          msg_length = @buffer[0, 4].unpack("L").first
          if msg_length && size >= msg_length
            data = @buffer.slice!(0, msg_length)
            yield data.unpack("LLLLLQLLa*")
          else
            break
          end
        else
          break
        end
      end
    end
  end
end