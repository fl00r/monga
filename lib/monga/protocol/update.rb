module Monga::Protocol
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

        msg = ::BinUtils.append_int32_le!(nil, 0)
        msg << full_name << Monga::NULL_BYTE
        ::BinUtils.append_int32_le!(msg, flags)
        msg << BSON::BSON_C.serialize(query).to_s
        msg << BSON::BSON_C.serialize(update).to_s
        msg
      end
    end
  end
end