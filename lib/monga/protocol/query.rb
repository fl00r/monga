module Monga::Protocol
  class Query < Monga::Request
    op_name :query

    FLAGS = {
      tailable_cursor: 1,
      slave_ok: 2,
      no_cursor_timeout: 4,
      await_data: 5,
      exhaust: 6,
      partial: 7,
    }

    def body
      @body ||= begin
        skip = @options[:skip] || 0
        limit = get_limit
        selector = @options[:selector] || {}

        query = {}
        query["$query"] = @options[:query] || {}
        query["$hint"] = @options[:hint] if @options[:hint]
        query["$orderby"] = @options[:sort] if @options[:sort]
        query["$explain"] = @options[:explain] if @options[:explain]

        b = BSON::ByteBuffer.new
        b.put_int(flags)
        BSON::BSON_RUBY.serialize_cstr(b, full_name)
        b.put_int(skip)
        b.put_int(limit)
        b.append!(BSON::BSON_C.serialize(query).to_s)
        b.append!(BSON::BSON_C.serialize(selector).to_s) if selector.any?
        b
      end
    end

    private

    def get_limit
      if @options[:batch_size]
        @options[:batch_size]
      elsif @options[:limit]
        -@options[:limit]
      else
        0
      end
    end
  end
end