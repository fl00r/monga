module Monga::Requests
  class KillCursors < Monga::Request
    op_name :kill_cursors
    
    def body
      @body ||= begin
        cursor_ids = @options[:cursor_ids]

        b = BSON::ByteBuffer.new
        b.put_int(0)
        b.put_int(cursor_ids.size)
        cursor_ids.each do |cursor_id|
          b.put_long(cursor_id)
        end
        b
      end
    end
  end
end