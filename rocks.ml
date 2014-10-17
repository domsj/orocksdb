open Ctypes
open Foreign

module CBoolean = struct
  let uchar_true = Unsigned.UChar.of_int 1
  let uchar_false = Unsigned.UChar.of_int 0

  let to_uchar = function
    | true -> uchar_true
    | false -> uchar_false

  let to_int = function
    | true -> 1
    | false -> 0
end

module type RocksType = sig
  val name : string
end
module CreateConstructors_(T : RocksType) = struct
  type t = unit ptr
  let t : t typ = ptr void

  let create_no_gc =
    foreign
      ("rocksdb_" ^ T.name ^ "_create")
      (void @-> returning t)

  let destroy =
    foreign
      ("rocksdb_" ^ T.name ^ "_destroy")
      (t @-> returning void)

  let create () =
    let t = create_no_gc () in
    Gc.finalise (fun t -> destroy t) t;
    t
end

module Options = struct
  module C = CreateConstructors_(struct let name = "options" end)
  include C

  let _set_create_if_missing =
    foreign
      "rocksdb_options_set_create_if_missing"
      (t @-> uchar @-> returning void)

  let set_create_if_missing t b =
    _set_create_if_missing t (CBoolean.to_uchar b)
end

module WriteOptions = struct
  module C = CreateConstructors_(struct let name = "writeoptions" end)
  include C

  let _set_disable_WAL =
    foreign
      "rocksdb_writeoptions_disable_WAL"
      (t @-> int @-> returning void)
  let set_disable_WAL t b =
    _set_disable_WAL t (CBoolean.to_int b)
end

module ReadOptions = struct
  module C = CreateConstructors_(struct let name = "readoptions" end)
  include C
end

module WriteBatch = struct
  module C = CreateConstructors_(struct let name = "writebatch" end)
  include C

  let clear =
    foreign
      "rocksdb_writebatch_clear"
      (t @-> returning void)

  let count =
    foreign
      "rocksdb_writebatch_count"
      (t @-> returning int)

  let put =
    foreign
      "rocksdb_writebatch_put"
      (t @->
       ptr char @-> size_t @->
       ptr char @-> size_t @->
       returning void)

  let delete =
    foreign
      "rocksdb_writebatch_delete"
      (t @->
       ptr char @-> size_t @->
       returning void)

end

module RocksDb = struct
  type t = unit ptr
  let t : t typ = ptr void

  let open_db =
    foreign
      "rocksdb_open"
      (Options.t @-> string @-> ptr string_opt @-> returning t)

  let close =
    foreign
      "rocksdb_close"
      (t @-> returning void)

  let put =
    foreign
      "rocksdb_put"
      (t @-> WriteOptions.t @->
       ocaml_string @-> size_t @-> ocaml_string @-> size_t @->
       ptr string_opt @-> returning void)

  let write =
    foreign
      "rocksdb_write"
      (t @-> WriteOptions.t @-> WriteBatch.t @->
       ptr string_opt @-> returning void)

  let get =
    foreign
      "rocksdb_get"
      (t @-> ReadOptions.t @->
       ocaml_string @-> size_t @-> ptr size_t @->
       ptr string_opt @->
       returning (ptr char))

end

let () =
  let options = Options.create () in
  Options.set_create_if_missing options true;
  let err_pointer = allocate string_opt None in
  let assert_no_error () =
    match !@ err_pointer with
    | None -> ()
    | Some err -> failwith err in
  let db =
    RocksDb.open_db
      options
      "aname"
      err_pointer
  in
  assert_no_error ();
  let write_options = WriteOptions.create () in
  RocksDb.put
    db write_options
    (ocaml_string_start "mykey") (Unsigned.Size_t.of_int 5)
    (ocaml_string_start "avalue") (Unsigned.Size_t.of_int 6)
    err_pointer;
  assert_no_error ();
  let read key =
    let read_options = ReadOptions.create () in
    let res_size = allocate size_t (Unsigned.Size_t.of_int 8) in
    let res =
      RocksDb.get
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
  RocksDb.close db
