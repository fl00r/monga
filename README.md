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

## Find

`find` method allways returns Cursor.
You can chain `skip`, `limit`, `batch_size` methods.
`all` will return all matching documents.
`each_doc` will return document into block.
`each_batch` will return batch into block.
For big collections iterating with small batches is a good choice.

```ruby
# All docs
collection.find.all
# All matching docs
collection.find(name: "Peter").all
# skip and limit
collection.find(moderated: true).skip(20).limit(10).all
# iterating over cursor
collection.find(country: "Japan").each_doc do |doc|
  puts doc.inspect
end
# Iterating over cursor with predefined batch size
collection.find(country: "China").batch_size(10_000).skip(1_000_000).each_doc do |chineese|
  puts chineese.name
end
```

## Insert

`insert` method will puts data into socket without waiting for response.
`safe_insert` method will send current request and then `getLastError` request. So it will be blocked till MongoDB server returns response. If response contains an error it will raise it.

You could use `continue_on_error` flag if you use "batch" insert. In this case MongoDB will try to insert all items in batch and then returns an error if any happened. Otherwise MongoDB will fail on first bad insert and won't continue.

Also you could pass following flags for `safe_insert` method:

  * j
  * fsync
  * w
  * wtimeout

More info about safe methods http://docs.mongodb.org/manual/reference/command/getLastError/#dbcmd.getLastError

```ruby
collection.insert(_id: 1, name: "Peter")
collection.safe_insert(_id: 1, name: "Peter")
#=> Duplicate key error
collection.safe_insert(_id: 2, name: "Ivan")

# Batch insert
batch = [
  { _id: 3, name: "Nick" },
  { _id: 2, name: "Mary" },
  { _id: 4, name: "Kate" }
]
collection.safe_insert(batch)
#=> Duplicate error key
collection.first(_id: 3)
#=> { _id: 3, name: "Nick" }
collection.first(_id: 4)
#=> nil

# Batch insert with `continue_on_error` flag
collection.safe_insert(batch, continue_on_error: true)
#=> Duplicate key error
# but all non existing docs are saved
collection.first(_id: 4)
#=> { _id: 4, name: "Kate" }
```

## Update

`update` method will also only puts data into socket without waiting for any response.
`safe_update` will raise an error if MongoDB can't update document.
You could use `upsert` and `multi_update` flags. With `upsert` it will insert current document if it doesn't present in database. With `multi_update` it will update all matching documents, otherwise only firtst will be updated.
Also `j`, `fsync`, `w`, `wtimeout` flags are available for `safe_update` mthod.

```ruby
collection.insert(_id: 1, name: "Peter", job: "Dancer")
collection.insert(_id: 2, name: "Peter", job: "Painter")

collection.update( 
  { name: "Peter" }, 
  { "$set" => { job: "Driver" } }
)
collection.find(name: "Peter").all
#=> [ 
#=>   { _id: 1, name: "Peter", job: "Driver" },
#=>   { _id: 2, name: "Peter", job: "Painter" }
#=> ]
collection.update( 
  { name: "Peter" }, 
  { "$set" => { job: "Singer" } },
  { multi_update: true }
)
collection.find(name: "Peter").all
#=> [ 
#=>   { _id: 1, name: "Peter", job: "Singer" },
#=>   { _id: 2, name: "Peter", job: "Singer" }
#=> ]
collection.update(
  { name: "Biork" },
  { "$set" => { job: "Artist" } }
)
collection.first(name: "Bjork")
#=> nil
collection.update(
  { name: "Biork" },
  { "$set" => { job: "Artist" } },
  { upsert: true }
)
collection.first(name: "Bjork")
#=> { _id: "Some id", name: "Bjork", job: "Artist" }
```

## Delete
Same as `insert` and `update` it has got `safe_delete` method and `j`, `fsync`, `w`, `wtimeout` flags.
Also it supports `single_remove` flag if you want to delete first matching dcument.

```ruby
batch = [
  { _id: 1, name: "Antonio" },
  { _id: 2, name: "Antonio" },
  { _id: 3, name: "Antonio" }
]
collection.safe_insert(batch)
collection.count
#=> 3
collection.safe_delete({ name: "Antonio" }, single_remove: true)
collection.count
#=> 2
collection.safe_delete(name: "Antonio")
collection.count
#=> 0
```

## Counting

```ruby
# All items
collection.count
# Query
collection.count(query: { name: "Peter" })
# Limit, skip
collection.count(query: { name: "Peter" }, limit: 10, skip: 5)
```
