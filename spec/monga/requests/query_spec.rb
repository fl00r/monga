require 'spec_helper'

describe Monga::Requests::Query do
  include Helpers::Truncate

  before do
    EM.run do
      documents = [
        { author: "Madonna", title: "Burning Up" },
        { author: "Madonna", title: "Freezing" },
        { author: "Bjork", title: "Song" },
      ]
      Monga::Requests::Insert.new(DB, COLLECTION.name, { documents: documents }).perform
      EM.add_timer(0.05){ EM.next_tick{ EM.stop }}
    end
  end

  it "should fetch one document" do
    EM.run do
      command = { query: { author: "Madonna" }, limit: 2 }
      req = Monga::Requests::Query.new(DB, COLLECTION.name, command).callback_perform
      req.callback do |res|
        EM.stop
      end
    end
  end

end