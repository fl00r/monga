require 'spec_helper'

describe Monga::Collection do
  before do
    EM.run do
      @client = Monga::Client.new(type: :em, pool_size: 10)
      @db = @client["dbTest"]
      @collection = @db["testCollection"]
      @collection.safe_remove do |err, resp|
        raise err if err
        EM.stop
      end
    end
  end

  it "should insert one document" do
    EM.run do
      count = 0
      n = 1000
      n.times do |i|
        @collection.safe_insert(title: "Doc #{i}") do
          count += 1
          if count == n
            @collection.count do |err, count|
              count.must_equal n
              @collection.find.batch_size(2).each_batch do |err, batch, iter|
                count -= batch.size
                raise err if err
                if iter
                  iter.next
                else
                # docs.size.must_equal n
                # docs.each do |doc|
                #   doc["title"]["Doc"].must_equal "Doc"
                # end
                p count
                  EM.stop
                end
              end
            end
          end
        end
      end
    end
  end

  it "should safe_insert" do
    EM.run do
      @collection.safe_insert(title: "Doc") do |err, resp|
        resp["ok"].must_equal 1.0
        EM.stop
      end
    end
  end
end