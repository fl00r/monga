module Monga::Requests
  class GetMore
    def body
      @body ||= 
        batch_size = @options[:batch_size] || 0
        cursor_id = @options[:cursor_id]

        b = BSON::ByteBuffer.new
        b.put_int(0)
        BSON::BSON_RUBY.serialize_cstr(b, full_name)
        b.put_int(batch_size)
        b.put_long(cursor_id)
        b
      end
    end
  end
end