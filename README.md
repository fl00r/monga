# Monga

MongoDB Ruby Driver on EventMachine. Supports callback and synchronous (em-synchrony) interfaces.

Currently in deep development. Not usable.

## Installation

Add this line to your application's Gemfile:

    gem 'monga'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install monga

## API

### CONNECTION

```ruby
connection = Monga::Connection.new("localhost", 27017)
db = connection["myDb"]
collection = db["myCollection"]
```

### INSERT

`insert` method accepts two params: document and options. Valid option is only one: `continue_on_error` which will set up `ContinueOnError` flag on insert operation.

From [MongoDB Wire Protocol Documentation](http://docs.mongodb.org/meta-driver/latest/legacy/mongodb-wire-protocol/#wire-op-query)*

* Most of quotes are copypasted from this paper.

> If set, the database will not stop processing a bulk insert if one fails (eg due to duplicate IDs). This makes bulk insert behave similarly to a series of single inserts, except lastError will be set if any insert fails, not just the last one. If multiple errors occur, only the most recent will be reported by getLastError. (new in 1.9.1)

Also `safe_insert` method provided, which will return Deferrable object. There are some options to manage your paranoia degree:

> j (boolean) – If true, wait for the next journal commit before returning, rather than a full disk flush. If mongod does not have journaling enabled, this option has no effect.

> w – When running with replication, this is the number of servers to replicate to before returning. A w value of 1 indicates the primary only. A w value of 2 includes the primary and at least one secondary, etc. In place of a number, you may also set w to majority to indicate that the command should wait until the latest write propagates to a majority of replica set members. If using w, you should also use wtimeout. Specifying a value for w without also providing a wtimeout may cause getLastError to block indefinitely.

> fsync (boolean) – If true, wait for mongod to write this data to disk before returning. Defaults to false. In most cases, use the j option to ensure durability and consistency of the data set.

> wtimeout (integer) – Optional. Milliseconds. Specify a value in milliseconds to control how long to wait for write propagation to complete. If replication does not complete in the given timeframe, the getLastError command will return with an error status.

```ruby
# Simple insert
collection.insert(author: "Madonna", title: "Burning Up")
#=> request_id

# Batch insert with continue_on_error option
collection.insert([{ author: "Madonna", title: "Burning Up" }, { author: "Madonna", title: "Freezing" }], { continue_on_error: true })
#=> request_id

# safe insert
request = collection.safe_insert(author: "Madonna", title: "Burning Up")
#=> Deferrable Object
request.callback{ |res| puts "ok"}
request.errback{ |err| puts "ough, #{err.message}"}

# safe insert with safe options
request = collection.safe_insert({ author: "Madonna", title: "Burning Up" }, 
  { w: 2, fsync: true })
#=> Deferrable Object
request.callback{ |res| puts "ok"}
request.errback{ |err| puts "ough, #{err.message}"}
```

### FIND AND CURSOR

Each find request internally creates cursor but returns all fetched data into callback. It could be inefficient for big amount of fetched data. So you can work with cursor manually by calling `cursor` method on find request.

```ruby
request = collection.find(artist: "Madonna")
request.callback do |docs|
  puts "Documents returned: #{docs.size}"
end

cursor = collection.find(artist: "Madonna").cursor
cursor_iterator = cursor.each_doc do |doc|
  puts "I have got new doc: #{doc}"
end
cursor_iterator.callback do
  puts "Cursor has finished it's job"
end
```

You can call skip, limit and batch_size method on find request
* skip - how many docs should be skipped
* limit - how many docs should be fetched from database
* batch_size - how many docs should be fetched by cursor on each GET_MORE operation (less batch_size will provide more queries but more releases into Event Loop)

## Features

* In Progress

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
