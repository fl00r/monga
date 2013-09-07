require 'spec_helper'

describe Monga::Collection do
  before do
    EM.run do
      @client = Monga::Client.new(type: :em, pool_size: 10, servers: ["188.93.61.42:27017", "188.93.61.42:27018", "188.93.61.42:27019"])
      @db = @client["dbTest"]
      @collection = @db["testCollection"]
      @collection.safe_remove do |err, resp|
        raise err if err
        docs = []
        10.times do |i|
          docs << { artist: "Madonna", title: "Track #{i+1}" }
          docs << { artist: "Radiohead", title: "Track #{i+1}" }
        end
        @collection.safe_insert(docs) do |err|
          raise err if err
          EM.stop
        end
      end
    end
  end

    describe "insert" do
      before do
        EM.run do
          @collection.safe_ensure_index({ "personal_id" => 1 }, { unique: true, sparse: true }) do |err, resp|
            raise err if err
            EM.stop
          end
        end
      end

      after do
        EM.run do
          @collection.drop_index( personal_id: 1 ) do |err, resp|
            raise err if err
            EM.stop
          end
        end
      end

      # it "should insert single doc" do
      #   EM.run do
      #     doc = { name: "Peter", age: 18 }
      #     @collection.safe_insert(doc) do |err, resp|
      #       @collection.find(name: "Peter").all do |err, resp|
      #         resp.size.must_equal 1
      #         resp.first["age"].must_equal 18
      #         EM.stop
      #       end
      #     end
      #   end
      # end

      # it "should insert batch of docs" do
      #   EM.run do
      #     docs = [{ name: "Peter", age: 18 }, {name: "Jhon", age: 18}]
      #     @collection.safe_insert(docs) do |err, resp|
      #       @collection.find(age: 18).all do |err, resp|
      #         resp.size.must_equal 2
      #         EM.stop
      #       end
      #     end
      #   end
      # end

      it "should fail on uniq index" do
        EM.run do
          docs = [{ name: "Peter", age: 18, personal_id: 20 }, {name: "Jhon", age: 18, personal_id: 20}, {name: "Rebeca", age: 21, personal_id: 5}]
          @collection.safe_insert(docs) do |err, resp|
            (Monga::Exceptions::QueryFailure === err).must_equal true
            @collection.count do |err, cnt|
              cnt.must_equal 21
              EM.stop
            end
          end
        end
      end

      # it "should continue_on_error" do
      #   EM.run do
      #     docs = [{ name: "Peter", age: 18, personal_id: 20 }, {name: "Jhon", age: 18, personal_id: 20}, {name: "Rebeca", age: 21, personal_id: 5}]
      #     @collection.safe_insert(docs, continue_on_error: true) do |err, resp|
      #       (Monga::Exceptions::QueryFailure === err).must_equal true
      #       @collection.count do |err, cnt|
      #         cnt.must_equal 22
      #         EM.stop
      #       end
      #     end
      #   end
      # end
    end

end
