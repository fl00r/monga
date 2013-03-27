# Monga

[MongoDB](http://www.mongodb.org/) Ruby Client on [EventMachine](https://github.com/eventmachine/eventmachine).

This client is under development. You can try [em-mongo](https://github.com/bcg/em-mongo).

## To Do List

### Connection
* [x] Connection to single instance
* [x] Autoreconnect
* [ ] Master Slave connection with SlaveOk
* [ ] Replica Sets Support
* [ ] Sharding Support

### Protocol
* [x] OP_QUERY
* [x] OP_GET_MORE
* [ ] OP_KILL_CURSORS
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

### Collection
* QUERY_OP
    * [x] find
    * [x] find_one (first)
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
* INDEXES
    * [x] ensure_index
    * [x] drop_index
    * [x] drop_indexes
    * [x] get_indexes
* [x] count
* [x] all
* [x] cursor

### Cursor
* [x] limit
* [x] skip
* [x] batch_size
* [x] get_more
* [x] next_document
* [x] next_batch
* [x] each_doc
* [ ] Flags
    * [ ] tailable_cursor
    * [ ] slave_ok
    * [ ] no_cursor_timeout
    * [ ] await_data
    * [ ] exhaust
    * [ ] partial

# ISSUES handled with

Some commands, such as `db.getLastError`, `db.count` and other `db.commands` requires `numberToReturn` in OP_QUERY to be setted as `-1`. Also this commands should return a response. If nothing returned it should be interpreted as an Exception. Also, in contrast to the other queries it could return `errmsg` which should be interpreted as an Exception too. Other query methods could return `err` response.

To create index you can't call any `db.ensureIndex` command but you should insert a document into `sytem.indexes` collection manually. But to drop index you should call specific `db.dropIndexes` command.

`multi_update` flag works only with `$` commands (i.e. `$set: { title: "blahblah" }`)