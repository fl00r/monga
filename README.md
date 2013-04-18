It is now completely rewritten with support of all kind of interfaces: blocking (TCP Socket), async (EventMachine), sync (Fibers). So API will be changed from Deferrable to callback (NodeJS style).

# Monga

[MongoDB](http://www.mongodb.org/) Ruby Client on [EventMachine](https://github.com/eventmachine/eventmachine). Also it supports synchrony mode ([em-synchrony](https://github.com/igrigorik/em-synchrony)).

This client is under development. You can try [em-mongo](https://github.com/bcg/em-mongo).

Client supports MongoDB 2.4. Some features won't work in lower versions.

## Introduction

```ruby
require 'monga'

EM.run do
    # Simple client
    client = Monga::Client.new(pool_size: 5)

    # Replica Set Client
    servers = [
        { host: "123.123.123.123", port: 27017},
        { host: "123.123.123.124", port: 27017},
        { host: "123.123.123.125", port: 27017},
    ]
    replica_set_client = Monga::ReplicaSetClient.new(servers: servers, pool_size: 10, read_pref: :primary_preferred)

    # Get collection
    db = client["myDb"]
    collection = db["myCollection"]

    # Queries
    collection.insert title: "Some document"
    collection.insert title: "Another document"

    req = collection.find.all
    req.callback do |documents|
        puts "I've got: #{documents.size} docs"
    end

    # Cursor
    cursor = collection.find.cursor.each_doc do |doc|
        puts doc["title"]
    end
    cursor.callback do
        puts "Cursor finished, now we will remove all docs"
        collection.remove
    end
    cursor.errback do
        puts "Error happend while following cursor"
    end

    # Tailable cursor on Capped collection
    req = db.create_collection("cappedColelction", capped: true, size: 1024*10)
    req.errback{ |err| p err }
    req.callback do
        collection = db["cappedColelction"]
        i = 0
        cursor = collection.find(artist: "Madonna").batch_size(10).cursor(tailable_cursor: true).each_doc do |track|
            i += 1
            puts "We have got new track: #{track['title']}"
            if i == 2
                puts "Let's kill cursor right now"
                cursor.kill
            end
        end
        cursor.callback do
            puts "Looks like somebody stopped me"
            collection.drop
            EM.stop
        end
        cursor.errback do |err|
            puts "Error happened #{err}"
            collection.drop
            EM.stop
        end
        collection.insert([{artist: "Madonna", title: "Frozen"}, {artist: "Madonna", title: "Burning Up"}])
    end
end
```

**Synchronouse mode**
*under development*

```ruby
require 'monga'
require 'monga/synchrony'
require 'em-synchrony'

EM.synchrony do
    client = Monga::Client.new
    collection = client["myDb"]["myCollection"]
    data = collection.find.all
    data.each do |doc|
        puts doc
    end
    collection.safe_insert(title: "My Title")
    row = collection.first(title: "My Title")
    puts row.title
    EM.stop
end
```

And also

* collection#ensure_index
* collection#drop
* collection#remove
* collection#update

and so on...

## To Do List

* [ ] Write a Wiki
* [ ] Write comments
* [ ] Grammar improvement ;)

### Clients
* [x] Client (Single instance connection)
* [x] ReplicaSetClient
* [ ] MasterSlaveClient
* [x] ReadPref
* [ ] Sharding Support

### Connection
* [x] Connection
* [x] Autoreconnect
* [x] Connection Pool

### Protocol
* [x] OP_QUERY
* [x] OP_GET_MORE
* [x] OP_KILL_CURSORS
* [x] OP_INSERT
* [x] OP_UPDATE
* [x] OP_DELETE
* [x] OP_REPLY

### Database
* [x] create_collection
* [x] drop_collection
* [x] get_last_error
* [x] drop_indexes
* [x] get_indexes
* Authentication
    * [ ] login
    * [ ] logout
    * [ ] add_user
* [ ] check maxBsonSize / validate
* [x] cmd
* [x] eval
* [ ] where

### Collection
* QUERY_OP
    * [x] find
    * [x] find_one (first)
    * [ ] sorting
* INSERT_OP
    * [x] insert (single)
    * [x] insert (batch)
    * [x] safe_insert
    * FLAGS
        * [x] continue_on_error
* UPDATE_OP
    * [x] update
    * [x] safe_update
    * FLAGS
        * [x] upsert
        * [x] multi_update
* DELETE_OP
    * [x] delete
    * [x] safe_delete
    * FLAGS
        * [x] single_remove
* INDEXES
    * [x] ensure_index
    * [x] drop_index
    * [x] drop_indexes
    * [x] get_indexes
* [x] count
* [x] all
* [x] cursor
* [ ] DBRef

### Cursor
* [x] limit
* [x] skip
* [x] batch_size
* [x] get_more
* [x] next_document
* [x] next_batch
* [x] each_doc
* [x] kill
* [x] mark_to_kill
* [x] batch_kill
* [x] explain
* [x] hint
* Flags
    * [x] tailable_cursor
    * [x] slave_ok
    * [x] no_cursor_timeout
    * [x] await_data
    * [x] exhaust
    * [x] partial

# ISSUES handled with

Some commands, such as `db.getLastError`, `db.count` and other `db.commands` requires `numberToReturn` in OP_QUERY to be setted as `-1`. Also this commands should return a response. If nothing returned it should be interpreted as an Exception. Also, in contrast to the other queries it could return `errmsg` which should be interpreted as an Exception too. Other query methods could return `err` response.

To create index you can't call any `db.ensureIndex` command but you should insert a document into `sytem.indexes` collection manually. To get list of indexes you should fetch all documents from this collection. But to drop index you should call specific `db.dropIndexes` command.

`multi_update` flag works only with `$` commands (i.e. `$set: { title: "blahblah" }`)