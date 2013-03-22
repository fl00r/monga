# require 'spec_helper'

# describe Monga::Connection do
#   it "should establish connection" do
#     EM.run do
#       connection = Monga::Connection.connect
#       collection = connection["stathub.music_stats"]
#       request = collection.find({item_id1: "7861689"})
#       # message = Monga::Requests::Query.new(collection, 0, 10, { item_id1: "7861689" }).full_message
#       # connection.send_command(message.to_s)
#       # EM.next_tick{ EM.stop }
#       request.callback do |a| 
#         p a
#         EM.stop
#       end
#       request.errback{ |b| p b }
#     end
#   end
# end