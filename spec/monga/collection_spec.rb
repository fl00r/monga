require 'spec_helper'

describe Monga::Collection do
  describe "indexes" do
    it "should create then update index with version and finally drop it" do
      EM.run do
        COLLECTION.ensure_index(field1: 1)
        req = COLLECTION.get_indexes
        req.callback do |res|
          res
        end
      end
    end
  end
end