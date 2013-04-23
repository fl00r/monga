module Monga::Protocol
  class GetMore < Monga::Request
    op_name :get_more
    
    def body
      @body ||= begin
        batch_size = @options[:batch_size] || 0
        cursor_id = @options[:cursor_id]

        msg = BinUtils.append_int32_le!(nil, 0)
        msg << full_name << Monga::NULL_BYTE
        BinUtils.append_int32_le!(msg, batch_size)
        BinUtils.append_int64_le!(msg, cursor_id)
        msg
      end
    end
  end
end