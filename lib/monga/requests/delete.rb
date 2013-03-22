module Monga::Requests
  class Delete < Monga::Request
    op_name :delete

    FLAGS = { 
      single_remove: 0,
    }

    def body
      @body ||= begin
        query = @options[:query]

        b = BSON::ByteBuffer.new
        b.put_int(0)
        BSON::BSON_RUBY.serialize_cstr(b, @collection.full_name)
        b.put_int(flags)
        b.append!(BSON::BSON_C.serialize(query).to_s)
        b
      end
    end

  end
end