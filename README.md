[![Build Status](https://travis-ci.org/fl00r/monga.png?branch=master)](https://travis-ci.org/fl00r/monga)

# Monga

Yet another [MongoDB](http://www.mongodb.org/) Ruby Client.

It supports three kind of interfaces:

  * Asynchronous over [EventMachine](https://github.com/eventmachine/eventmachine)
  * Synchronous (on Fibers)
  * Blocking (over TCPSocket, [kgio](http://bogomips.org/kgio/) actually)

You can also try:

  * [em-mongo](https://github.com/bcg/em-mongo) with Eventmachine inside
  * Official [mongo-ruby-driver](https://github.com/mongodb/mongo-ruby-driver) from 10gen
  * [Moped](http://mongoid.org/en/moped/) from Mongoid guys

## Introduction

Asynchronous API will be familiar to Node.js developers. Instead of Deferrable Object you will receive `err, response` into callback.

```ruby
EM.run do
  client = Monga::Client.new(type: :em)
  db = client["testDb"]
  collection = db["testCollection"]

  # Fire and forget
  collection.insert(artist: "Madonna", title: "Frozen")

  # Safe method
  collection.safe_insert(artist: "Madonna", title: "Burning Up") do |err, response|
    if err
      puts "Ha, an error! #{err.message}"
    else
      puts "Job is done. Let's do more job"

      # Cursor
      collection.find.batch_size(100).limit(500).each_doc do |err, doc, iter|
        if iter
          puts "What have we got here: #{doc['title']}"
          iter.next
        else
          puts "No more documents in collection"
          EM.stop
        end
      end
      # Yes, you should call `iter.next`, welcome to callback world!
    end
  end
end
```

Synchronous mode is more simple. It is just like blocking mode, but you can use pool of fibers to make it as fast as lightning.

```ruby
EM.synchrony do
  client = Monga::Client.new(type: :sync)
  db = client["testDb"]
  collection = db["testCollection"]

  # Fire and forget
  collection.insert(artist: "Madonna", title: "Frozen")

  # Safe method
  collection.safe_insert(artist: "Madonna", title: "Burning Up")
  puts "Job is done"

  # Cursor
  docs = []
  collection.find.batch_size(100).limit(500).each_doc do |doc|
    puts "What have we got here: #{doc['title']}"
    docs << doc
  end
  puts "We have got #{docs.size} documents in this pretty array"

  EM.stop
end
```

Blocking mode is as simple as a potato

```ruby
# client = Monga::Client.new(type: :block)
client = Monga::Client.new
db = client["testDb"]
collection = db["testCollection"]

# Fire and forget
collection.insert(artist: "Madonna", title: "Frozen")

# Safe method
collection.safe_insert(artist: "Madonna", title: "Burning Up")
puts "Job is done"

# Cursor
docs = []
collection.find.batch_size(100).limit(500).each_doc do |doc|
  puts "What have we got here: #{doc['title']}"
  docs << doc
end
puts "We have got #{docs.size} documents in this pretty array"
```