open Ctypes
open Foreign


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

type rocksdb_writeoptions_t = unit ptr
let rocksdb_writeoptions_t : rocksdb_writeoptions_t typ = ptr void

let rocksdb_writeoptions_create =
  foreign
    "rocksdb_writeoptions_create"
    (void @-> returning rocksdb_writeoptions_t)

let rocksdb_writeoptions_disable_WAL =
  foreign
    "rocksdb_writeoptions_disable_WAL"
    (rocksdb_writeoptions_t @-> int @-> returning void)

type rocksdb_t = unit ptr
let rocksdb_t : rocksdb_t typ = ptr void

let rocksdb_open =
  foreign
    "rocksdb_open"
    (rocksdb_options_t @-> string @-> ptr string_opt @-> returning rocksdb_t)

let rocksdb_close =
  foreign
    "rocksdb_close"
    (rocksdb_t @-> returning void)

let rocksdb_put =
  foreign
    "rocksdb_put"
    (rocksdb_t @-> rocksdb_writeoptions_t @->
     ocaml_string @-> size_t @-> ocaml_string @-> size_t @->
     ptr string_opt @-> returning void)

type rocksdb_readoptions_t = unit ptr
let rocksdb_readoptions_t : rocksdb_readoptions_t typ = ptr void

let rocksdb_readoptions_create =
  foreign
    "rocksdb_readoptions_create"
    (void @-> returning rocksdb_readoptions_t)

let rocksdb_get =
  foreign
    "rocksdb_get"
    (rocksdb_t @-> rocksdb_readoptions_t @->
     ocaml_string @-> size_t @-> ptr size_t @->
     ptr string_opt @->
     returning (ptr char))

let () =
  let options = rocksdb_options_create () in
  let utrue = Unsigned.UChar.of_int 1 in
  rocksdb_options_set_create_if_missing options utrue;
  let err_pointer = allocate string_opt None in
  let assert_no_error () =
    match !@ err_pointer with
    | None -> ()
    | Some err -> failwith err in
  let db =
    rocksdb_open
      options
      "aname"
      err_pointer
  in
  assert_no_error ();
  let write_options = rocksdb_writeoptions_create () in
  rocksdb_put
    db write_options
    (ocaml_string_start "mykey") (Unsigned.Size_t.of_int 5)
    (ocaml_string_start "avalue") (Unsigned.Size_t.of_int 6)
    err_pointer;
  assert_no_error ();
  let read key =
    let read_options = rocksdb_readoptions_create () in
    let res_size = allocate size_t (Unsigned.Size_t.of_int 8) in
    let res =
      rocksdb_get
        db read_options
        (ocaml_string_start key) (Unsigned.Size_t.of_int (String.length key))
        res_size err_pointer in
    if raw_address_of_ptr (to_voidp res) = 0L
    then None
    else begin
      let res' = string_from_ptr res (Unsigned.Size_t.to_int (!@ res_size)) in
      Some res'
    end in
  let show_string_option = [%derive.Show: string option] in
  print_endline (show_string_option (read "mykey"));
  print_endline (show_string_option (read "mykey2"));
  rocksdb_close db
