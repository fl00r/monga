require 'benchmark'
require 'em-synchrony'

TOTAL_INSERTS = 1000
TOTAL_READS = 20

chars = ('a'..'z').to_a
DOCS = [10, 100, 1000, 10000].map do |size|
  doc = {}
  doc[:title] = "Title"
  doc[:body] = size.times.map{ chars.sample }.join
  [size, doc]
end

# Mongo Ruby Driver

fork do
  require 'mongo'
  include Mongo

  Benchmark.bm do |x|
    collection = MongoClient.new.db("dbTest").collection("testCollection")

    DOCS.each do |size, doc|
      GC.start
      x.report("Mongo: Inserting #{size}b document") do
        TOTAL_INSERTS.times do
          collection.insert(doc.dup)
        end
      end

      GC.start
      x.report("Mongo: Reading #{size}b documents") do
        TOTAL_READS.times do
          collection.find.to_a
        end
      end

      collection.drop
    end
  end
end

Process.waitall
puts "---"*5

# Monga Driver (blocking mode)

fork do
  require File.expand_path('../../lib/monga', __FILE__)

  Benchmark.bm do |x|
    collection = Monga::Client.new.get_database("dbTest").get_collection("testCollection")

    DOCS.each do |size, doc|
      GC.start
      x.report("Monga (blocking): Inserting #{size}b document") do
        TOTAL_INSERTS.times do
          collection.safe_insert(doc)
        end
      end

      GC.start
      x.report("Monga (blocking): Reading #{size}b documents") do
        TOTAL_READS.times do
          collection.find.all
        end
      end

      collection.drop
    end
  end
end

Process.waitall
puts "---"*5

# Moped

fork do
  require 'moped'

  Benchmark.bm do |x|
    session = Moped::Session.new([ "127.0.0.1:27017" ])
    session.use("dbTest")

    DOCS.each do |size, doc|
      GC.start
      x.report("Moped: Inserting #{size}b document") do
        session.with(safe: true) do |safe|
          TOTAL_INSERTS.times do
            safe[:testCollection].insert(doc)
          end
        end
      end

      GC.start
      x.report("Moped: Reading #{size}b documents") do
        TOTAL_READS.times do
          session[:testCollection].find.to_a
        end
      end

      session[:testCollection].drop
    end
  end
end

Process.waitall

# # require 'moped'

# # include Mongo

# Benchmark.bm do |x|
#   total = 1000
#   fetch = 50
#   # mongo_collection = MongoClient.new.db("dbTest").collection("testCollection")
#   monga_collection = Monga::Client.new(type: :block).get_database("dbTest").get_collection("testCollection")
#   Monga.logger.level = Logger::ERROR
#   # moped_session = Moped::Session.new([ "127.0.0.1:27017" ])
#   # moped_session.use "dbTest"

#   document = {}
#   document[:title] = "Some title"
#   document[:body] = 10000.times.map{ chars.sample } * ""

#   # sleep 0.5

#   # GC.start

#   # x.report("Inserting with mongo") do
#   #   total.times do |i|
#   #     mongo_collection.insert(document.dup)
#   #   end
#   # end

#   # GC.start

#   # x.report("Fetching with mongo") do
#   #   fetch.times do
#   #     mongo_collection.find.to_a
#   #   end
#   # end
#   # mongo_collection.drop

#   # sleep 0.5

#   # GC.start

#   x.report("Inserting with monga") do
#     total.times do |i|
#       monga_collection.safe_insert(document)
#     end
#   end

#   GC.start

#   x.report("Fetching with monga") do
#     fetch.times do
#       monga_collection.find.all
#     end
#   end

#   monga_collection.drop

#   # sleep 0.5

#   # GC.start

#   # x.report("Inserting with moped") do
#   #   moped_session.with(safe: true) do |safe|
#   #     total.times do |i|
#   #       safe[:testCollection].insert(document)
#   #     end
#   #   end
#   # end

#   # GC.start

#   # x.report("Fetching with moped") do
#   #   fetch.times do
#   #     moped_session[:testCollection].find.to_a
#   #   end
#   # end

#   # monga_collection.drop
# end





