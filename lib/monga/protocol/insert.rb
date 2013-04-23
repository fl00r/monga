module Monga::Protocol
  class Insert < Monga::Request
    op_name :insert

    FLAGS = { 
      continue_on_error: 0,
    }

    def body
      @body ||= begin
        documents = @options[:documents]

        msg = BinUtils.append_int32_le!(nil, flags)
        msg << full_name << Monga::NULL_BYTE
        case documents
        when Array
          documents.each do |doc|
            msg << BSON::BSON_C.serialize(doc).to_s
          end
        when Hash
          msg << BSON::BSON_C.serialize(documents).to_s
        end
        msg
      end
    end
  end
end