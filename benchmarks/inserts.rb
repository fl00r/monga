require 'benchmark'
require 'mongo'
require 'moped'
require File.expand_path('../../lib/monga', __FILE__)

include Mongo

Benchmark.bm do |x|
  total = 10000
  fetch = 50
  mongo_collection = MongoClient.new.db("dbTest").collection("testCollection")
  monga_collection = Monga::Client.new(type: :block).get_database("dbTest").get_collection("testCollection")
  Monga.logger.level = Logger::ERROR
  moped_session = Moped::Session.new([ "127.0.0.1:27017" ])
  moped_session.use "dbTest"

  document = {}
  document[:title] = "Some title"
  chars = ('a'..'z').to_a
  document[:body] = 100.times.map{ chars.sample } * ""

  sleep 0.5

  GC.start

  x.report("Inserting with mongo") do
    total.times do |i|
      mongo_collection.insert(document.dup)
    end
  end

  GC.start

  x.report("Fetching with mongo") do
    fetch.times do
      mongo_collection.find.to_a
    end
  end
  mongo_collection.drop

  sleep 0.5

  GC.start

  x.report("Inserting with monga") do
    total.times do |i|
      monga_collection.safe_insert(document.dup)
    end
  end

  GC.start

  x.report("Fetching with monga") do
    fetch.times do
      monga_collection.find.all
    end
  end

  monga_collection.drop

  sleep 0.5

  GC.start

  x.report("Inserting with moped") do
    moped_session.with(safe: true) do |safe|
      total.times do |i|
        safe[:testCollection].insert(document)
      end
    end
  end

  GC.start

  x.report("Fetching with moped") do
    fetch.times do
      moped_session[:testCollection].find.to_a
    end
  end

  monga_collection.drop
end





