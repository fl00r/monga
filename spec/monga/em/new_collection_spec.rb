require 'spec_helper'

describe Monga::Collection do
  describe "primary" do
    before do
      EM.run do
        @client = Monga::Client.new(type: :em, pool_size: 10, servers: ["127.0.0.1:27017", "127.0.0.1:27018", "127.0.0.1:27019"])
        @db = @client["dbTest"]
        @collection = @db["testCollection"]
        @collection.safe_remove do |err, resp|
          p resp
          raise err if err
          docs = []
          10.times do |i|
            docs << { artist: "Madonna", title: "Track #{i+1}" }
            docs << { artist: "Radiohead", title: "Track #{i+1}" }
          end
          p "---"
          @collection.safe_insert(docs) do |err|
            p "!!!!!!"
            raise err if err
            EM.stop
          end
        end
      end
    end

    # QUERY

    describe "query" do
      it "should fetch all documents" do
        EM.run do
          @collection.find.all do |err, docs|
            docs.size.must_equal 20
            EM.stop
          end
        end
      end

      it "should fetch all docs with skip and limit" do
        EM.run do
          @collection.find.skip(10).limit(4).all do |err, docs|
            docs.size.must_equal 4
            EM.stop
          end
        end
      end

      it "should fetch first" do
        EM.run do
          @collection.first do |err, doc|
            doc.keys.must_equal ["_id", "artist", "title"]
            EM.stop
          end
        end
      end
    end
  end
end