open Ctypes
open Foreign


module type ToCharPtrWithLength = sig
  type t
  val length : t -> int
  val to_char_ptr : t -> char ptr
end

module StringToCharPtr : ToCharPtrWithLength = struct
  type t = string
  let length = String.length

  let rec blit_string_to_bigarray src srcoff dst dstoff = function
    | 0 -> ()
    | len ->
      let c = String.get src srcoff in
      Bigarray.Array1.set dst dstoff c;
      blit_string_to_bigarray src (srcoff + 1) dst (dstoff + 1) (len - 1)

  let to_char_ptr s =
    let len = length s in
    let bigarray =
      Bigarray.Array1.create
        Bigarray.Char
        Bigarray.C_layout
        len in
    blit_string_to_bigarray s 0 bigarray 0 len;
    bigarray_start array1 bigarray
end

module Views = struct
  let bool_to_int =
    view
      ~read:(fun i -> i <> 0)
      ~write:(function true -> 1 | false -> 0)
      int

  let bool_to_uchar =
    view
      ~read:(fun u -> u <> Unsigned.UChar.zero)
      ~write:(function true -> Unsigned.UChar.one | false -> Unsigned.UChar.zero)
      uchar
end

module type RocksType = sig
  val name : string
end
module CreateConstructors_(T : RocksType) = struct
  type t = unit ptr
  let t : t typ = ptr void
  let type_name = T.name

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

  let create_setter property_name property_typ =
    foreign
      ("rocksdb_" ^ type_name ^ "_" ^ property_name)
      (t @-> property_typ @-> returning void)
end

module Options = struct
  module C = CreateConstructors_(struct let name = "options" end)
  include C

  let set_create_if_missing = create_setter "set_create_if_missing" Views.bool_to_uchar
end

module WriteOptions = struct
  module C = CreateConstructors_(struct let name = "writeoptions" end)
  include C

  let set_disable_WAL = create_setter "disable_WAL" Views.bool_to_int
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

  let put_raw =
    foreign
      "rocksdb_writebatch_put"
      (t @->
       ptr char @-> size_t @->
       ptr char @-> size_t @->
       returning void)
  let put batch key value =
    let key_len = Unsigned.Size_t.of_int (StringToCharPtr.length key) in
    let value_len = Unsigned.Size_t.of_int (StringToCharPtr.length value) in
    put_raw
      batch
      (StringToCharPtr.to_char_ptr key) key_len
      (StringToCharPtr.to_char_ptr value) value_len

  let delete_raw =
    foreign
      "rocksdb_writebatch_delete"
      (t @->
       ptr char @-> size_t @->
       returning void)

  let delete batch key =
    let key_len = Unsigned.Size_t.of_int (StringToCharPtr.length key) in
    delete_raw batch (StringToCharPtr.to_char_ptr key) key_len
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
