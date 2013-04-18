require 'spec_helper'
require 'helpers/synchrony'

describe Monga::Collection do
  before do
    @client = Monga::Client.new(type: :sync, pool_size: 10)
    @db = @client["dbTest"]
    @collection = @db["testCollection"]
    @collection.safe_remove
  end

  it "should insert one document" do
    @collection.safe_insert(title: "Tests")["ok"].must_equal 1.0
    @collection.find.first["title"].must_equal "Tests"
    @collection.find.all.size.must_equal 1
    @collection.count.must_equal 1
  end

  it "should insert multiple documents" do
    @collection.safe_insert([{title: "Test1"}, {title: "Test2"}])["ok"].must_equal 1.0
    @collection.count.must_equal 2
  end
end

