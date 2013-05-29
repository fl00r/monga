module Monga::Protocol
  class Insert < Monga::Request
    op_name :insert

    FLAGS = { 
      continue_on_error: 0,
    }

    def body
      @body ||= begin
        documents = @options[:documents]

        msg = ::BinUtils.append_int32_le!(nil, flags)
        msg << full_name << Monga::NULL_BYTE
        case documents
        when Array
          documents.each do |doc|
            msg << doc.to_bson
          end
        when Hash
          # msg << BSON::BSON_C.serialize(documents).to_s
          msg << documents.to_bson
        end
        msg
      end
    end
  end
end