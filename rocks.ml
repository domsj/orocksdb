open Ctypes
open Foreign


type rocksdb_t = unit ptr
let rocksdb_t : rocksdb_t typ = ptr void
type rocksdb_options_t = unit ptr
let rocksdb_options_t : rocksdb_options_t typ = ptr void

let rocksdb_options_create =
  foreign
    "rocksdb_options_create"
    (void @-> returning rocksdb_options_t)

let rocksdb_options_set_create_if_missing =
  foreign
    "rocksdb_options_set_create_if_missing"
    (rocksdb_options_t @-> uchar @-> returning void)

let rocksdb_writeoptions_disable_WAL =
  foreign
    "rocksdb_writeoptions_disable_WAL"
    (rocksdb_options_t @-> int @-> returning void)

let rocksdb_open =
  foreign
    "rocksdb_open"
    (rocksdb_options_t @-> string @-> ptr string_opt @-> returning (ptr rocksdb_t))

let rocksdb_close =
  foreign
    "rocksdb_close"
    (ptr rocksdb_t @-> returning void)

let () =
  let options = rocksdb_options_create () in
  let utrue = Unsigned.UChar.of_int 1 in
  rocksdb_options_set_create_if_missing options utrue;
  let err_pointer = allocate string_opt None in
  let db =
    rocksdb_open
      options
      "aname"
      err_pointer
  in
  let () = match !@ err_pointer with
    | None -> print_endline "no error"
    | Some e -> print_endline e in
  rocksdb_close db
