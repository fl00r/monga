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
        limit = @options[:limit] || 0
        flags = @options[:flag_opts] || {}
        query = @options[:query]
        fields = @options[:fields]

        b = BSON::ByteBuffer.new
        b.put_int(flags)
        BSON::BSON_RUBY.serialize_cstr(b, @collection.name)
        b.put_int(skip)
        b.put_int(limit)
        b.append!(BSON::BSON_C.serialize(query).to_s)
        b
      end
    end

    private

    def flags
      f = 0
      bytes = @flag_opts.map{ |opt| FLAGS[opt] }.compact

      return f if bytes.empty?

      bytes.each do |b|
        f = f ^ 2**b
      end
    end
  end
end