# Monga

[MongoDB](http://www.mongodb.org/) Ruby Client on [EventMachine](https://github.com/eventmachine/eventmachine).

This client is under development. You can try [em-mongo](https://github.com/bcg/em-mongo).

## To Do List

### Connection
- [x] Connection to single instance
- [x] Autoreconnect
- [ ] Master Slave connection with SlaveOk
- [ ] Replica Sets Support

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
- [ ] find
- [ ] find_one
- [ ] insert
- [ ] update
- [ ] delete
- [ ] safe_* (insert/update/delete)
- [ ] get_indexes
- [ ] ensure_index
- [ ] ensure_index_with_version
- [ ] drop_index
- [ ] count

### Cursor
- [x] get all
- [x] each