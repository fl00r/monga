module Monga::Protocol
  class Delete < Monga::Request
    op_name :delete

    FLAGS = { 
      single_remove: 0,
    }

    def body
      @body ||= begin
        query = @options[:query]

        msg = ::BinUtils.append_int32_le!(nil, 0)
        msg << full_name << Monga::NULL_BYTE
        ::BinUtils.append_int32_le!(msg, flags)
        msg << query.to_bson
        msg
      end
    end
  end
end