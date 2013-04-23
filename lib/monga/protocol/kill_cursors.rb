module Monga::Protocol
  class KillCursors < Monga::Request
    op_name :kill_cursors

    def initialize(connection, options = {})
      @options = options
      @request_id = self.class.request_id
      @connection = connection
    end
    
    def body
      @body ||= begin
        cursor_ids = @options[:cursor_ids]

        msg = ::BinUtils.append_int32_le!(nil, 0, cursor_ids.size)
        ::BinUtils.append_int64_le!(msg, 0, *cursor_ids)
        msg
      end
    end
  end
end