require 'spec_helper'

describe Monga::Database do
  before do
    @client = Monga::Client.new
    @db = @client["dbTest"]
    @collection = @db["testCollection"]
  end

  it "should create collection"

  it "should drop collection"

  it "should count in collection"

  it "should drop index"

  it "should drop all indexes"

  describe "auth" do
    it "should add new user"

    it "should drop user"

    it "should auth user"

    it "should logout"
  end

  it "should run command"

  it "should eval javascript"

  describe "getLastError" do
    it "should get last error"

    it "should getLastError with fsync"

    it "should getLastError with replicas"
  end

  describe "aggregation" do
    it "should aggregate"
  end

  describe "map reduce" do
    it "should run map reduce"
  end
end