open Ctypes
open Foreign
open PosixTypes


type rocksdb_t = unit ptr
let rocksdb_t = ptr void
type rocksdb_options_t = unit ptr
let rocksdb_options_t = ptr void

let rocksdb_options_create =
  foreign
    "rocksdb_options_create"
    (void @-> returning rocksdb_options_t)

let rocksdb_open =
  foreign
    "rocksdb_open"
    (rocksdb_options_t @-> string @-> ptr string_opt @-> returning rocksdb_t)


let () =
  let options = rocksdb_options_create () in
  let _db =
    rocksdb_open
      options
      "aname"
      (allocate string_opt None)
  in
  print_endline "test"
