module Monga::Requests
  class Insert < Monga::Request
    op_name :insert

    FLAGS = { 
      continue_on_error: 0,
    }

    def body
      @body ||= begin
        documents = @options[:documents]

        b = BSON::ByteBuffer.new
        b.put_int(flags)
        BSON::BSON_RUBY.serialize_cstr(b, @collection.full_name)
        case documents
        when Array
          documents.each do |doc|
            b.append!(BSON::BSON_C.serialize(doc).to_s)
          end
        when Hash
          b.append!(BSON::BSON_C.serialize(documents).to_s)
        end
        b
      end
    end

  end
end