module Monga::Requests
  class Update < Monga::Request
    op_name :update

    FLAGS = { 
      upsert: 0,
      multi_update: 1,
    }

    def body
      @body ||= begin
        query = @options[:query]
        update = @options[:update]

        b = BSON::ByteBuffer.new
        b.put_int(0)
        BSON::BSON_RUBY.serialize_cstr(b, @collection.full_name)
        b.put_int(flags)
        b.append!(BSON::BSON_C.serialize(query).to_s)
        b.append!(BSON::BSON_C.serialize(update).to_s)
        b
      end
    end
  end
end