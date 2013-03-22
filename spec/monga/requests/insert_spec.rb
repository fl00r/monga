require 'spec_helper'

describe Monga::Requests::Insert do
  include Helpers::Truncate

  describe "simple insert" do
    it "should insert one document" do
      EM.run do
        COLLECTION.insert(author: "Madonna", title: "Burning Up")
        EM.add_timer(0.1){ EM.next_tick{ EM.stop } }
      end
    end

    it "should insert multiple documents" do
      EM.run do
        COLLECTION.insert([
          {author: "Madonna", title: "Burning Up"},
          {author: "Madonna", title: "Freezing"},
          {author: "Madonna", title: "Boiling"},
        ])
        EM.add_timer(0.1){ EM.next_tick{ EM.stop } }
      end
    end
  end

  # describe "fail on write to uniq index" do
  #   it "should fail after inserting duplicated document" do

  #   end

  #   it "should not fail because of continue_on_error" do

  #   end
  # end

  describe "safe_insert" do
    # it "should callback safe_insert" do
    #   EM.run do
    #     req = @collection.safe_insert(author: "Madonna", title: "Burning Up")
    #     req.callback{ |res| "glad for me" }
    #     req.errback{ |err| raise err }
    #   end
    # end

    # it "should errback safe_insert" do

    # end
  end
end