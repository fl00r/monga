# Monga

[MongoDB](http://www.mongodb.org/) Ruby Client on [EventMachine](https://github.com/eventmachine/eventmachine).

This client is under development. You can try [em-mongo](https://github.com/bcg/em-mongo).

## To Do List

### Connection
- [x] Connection to single instance
- [x] Autoreconnect
- [ ] Master Slave connection with SlaveOk
- [ ] Replica Sets Support
- [ ] Sharding Support

### Protocol
- [x] OP_QUERY
- [x] OP_GET_MORE
- [ ] OP_KILL_CURSORS
- [x] OP_INSERT
- [x] OP_UPDATE
- [x] OP_DELETE
- [x] OP_REPLY

### Database
- [x] create_collection
- [x] drop_collection
- [x] get_last_error

### Collection
- [x] QUERY_OP
-- [x] find
-- [x] find_one (first)
- [x] INSERT_OP
-- [x] insert (single)
-- [x] insert (batch)
-- [x] continue_on_error
- [ ] update
- [ ] delete
- [ ] safe_* (insert/update/delete)
- [x] get_indexes
- [x] ensure_index
- [ ] ensure_index_with_version
- [x] drop_index
- [ ] count
- [x] each
- [x] cursor

### Cursor
- [x] limit
- [x] skip
- [x] batch_size
- [x] get_more
- [x] next_document
- [ ] Flags
-- [ ] tailable_cursor
-- [ ] slave_ok
-- [ ] no_cursor_timeout
-- [ ] await_data
-- [ ] exhaust
-- [ ] partial