require 'ruby-prof'
require File.expand_path('../../lib/monga', __FILE__)
require 'mongo'
include Mongo

total = 100
# monga_collection = Monga::Client.new(type: :block).get_database("dbTest").get_collection("testCollection")
mongo_collection = MongoClient.new.db("dbTest").collection("testCollection")

total.times do |i|
  mongo_collection.insert(title: "Row #{i}")
end
RubyProf.start
mongo_collection.find.to_a

result = RubyProf.stop
mongo_collection.drop

# Print a flat profile to text
printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)



  mongo_collection = MongoClient.new.db("dbTest").collection("testCollection")
  mongo_collection.find.to_a