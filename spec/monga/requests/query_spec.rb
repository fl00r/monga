require 'spec_helper'

describe Monga::Requests::Query do
  # it "should pack message" do
  #   unpacked = [70, 1, 0, 2004, 0, "stathub.music_stats", 0, 10, {"title" => "Title"}]
  #   message = Monga::Requests::Query.new("stathub", "music_stats", 0, 10, { "title" => "Title" }).full_message
  #   packed = message.to_s.dup
  #   unp = packed.slice!(0, 20).unpack("LLLLL")
  #   index = packed.index("\x00")
  #   unp += packed.slice!(0, index).unpack("a*")
  #   packed.slice!(0,1)
  #   unp += packed.unpack("LLa*")
  #   unp[-1] = BSON::BSON_C.deserialize(unp.last)
  #   unp.must_equal unpacked
  # end
end