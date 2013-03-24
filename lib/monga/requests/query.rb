module Monga::Requests
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
        limit = @options[:limit] || -1
        query = @options[:query] || {}
        fields = @options[:fields] || {}

        b = BSON::ByteBuffer.new
        b.put_int(flags)
        BSON::BSON_RUBY.serialize_cstr(b, full_name)
        b.put_int(skip)
        b.put_int(limit)
        b.append!(BSON::BSON_C.serialize(query).to_s)
        b.append!(BSON::BSON_C.serialize(fields).to_s) if fields.any?
        b
      end
    end
  end
end