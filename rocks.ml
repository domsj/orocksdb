open Ctypes
open Foreign

(* TODO use ocaml_string where appropriate to avoid string copies *)

module type ToCharPtrWithLength = sig
  type t
  val length : t -> int
  val to_char_ptr : t -> char ptr
end

module StringToCharPtr = struct
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

  let err_pointer = allocate string_opt None
  let returning_error typ = ptr string_opt @-> returning typ
  let assert_no_error () =
    match !@ err_pointer with
    | None -> ()
    | Some err ->
      (* TODO error pointer should be cleared here so next
         operations don't return errors? *)
      failwith err
  let with_err_pointer f =
    let res = f err_pointer in
    assert_no_error ();
    res

  let open_db =
    let inner =
      foreign
        "rocksdb_open"
        (Options.t @-> string @-> ptr string_opt @-> returning t) in
    fun options name -> with_err_pointer (inner options name)

  let close =
    foreign
      "rocksdb_close"
      (t @-> returning void)

  let put =
    let inner =
      foreign
        "rocksdb_put"
        (t @-> WriteOptions.t @->
         ptr char @-> size_t @-> ptr char @-> size_t @->
         returning_error void) in
    fun t wo key value ->
      let key_len = Unsigned.Size_t.of_int (StringToCharPtr.length key) in
      let value_len = Unsigned.Size_t.of_int (StringToCharPtr.length value) in
      with_err_pointer
        (inner
           t wo 
           (StringToCharPtr.to_char_ptr key) key_len
           (StringToCharPtr.to_char_ptr value) value_len)

  let write =
    let inner =
      foreign
        "rocksdb_write"
        (t @-> WriteOptions.t @-> WriteBatch.t @->
         returning_error void) in
    fun t options batch -> with_err_pointer (inner t options batch)

  let get =
    let inner =
      foreign
        "rocksdb_get"
        (t @-> ReadOptions.t @->
         ocaml_string @-> size_t @-> ptr size_t @->
         returning_error (ptr char)) in
    fun t options key ->
      let key_len = Unsigned.Size_t.of_int (String.length key) in
      let res_size = allocate size_t (Unsigned.Size_t.of_int 0) in
      let res =
        with_err_pointer
          (inner
             t options
             (ocaml_string_start key) key_len
             res_size) in
      if (to_voidp res) = null
      then None
      else begin
        let res' = string_from_ptr res (Unsigned.Size_t.to_int (!@ res_size)) in
        Some res'
      end

end

module Iterator = struct
  type t = unit ptr
  let t : t typ = ptr void

  let create_no_gc =
    foreign
      "rocksdb_create_iterator"
      (RocksDb.t @-> ReadOptions.t @-> returning t)

  let destroy =
    foreign
      "rocksdb_iter_destroy"
      (t @-> returning void)

  let create db read_options =
    let t = create_no_gc db read_options in
    Gc.finalise (fun t -> destroy t) t;
    t

  let is_valid =
    foreign
      "rocksdb_iter_valid"
      (t @-> returning Views.bool_to_uchar)

  let seek_to_first =
    foreign
      "rocksdb_iter_seek_to_first"
      (t @-> returning void)

  let seek_to_last =
    foreign
      "rocksdb_iter_seek_to_last"
      (t @-> returning void)

  let seek_raw =
    foreign
      "rocksdb_iter_seek"
      (t @-> ptr char @-> size_t @-> returning void)

  let seek t key =
    let key_len = Unsigned.Size_t.of_int (String.length key) in
    seek_raw t (StringToCharPtr.to_char_ptr key) key_len

  let next =
    foreign
      "rocksdb_iter_next"
      (t @-> returning void)

  let prev =
    foreign
      "rocksdb_iter_prev"
      (t @-> returning void)

  let get_key_raw =
    foreign
      "rocksdb_iter_key"
      (t @-> ptr size_t @-> returning (ptr char))

  let get_key t =
    let res_size = allocate size_t (Unsigned.Size_t.of_int 0) in
    let res = get_key_raw t res_size in
    if (to_voidp res) = null
    then failwith (Printf.sprintf
                     "could not get key, is_valid=%b" (is_valid t))
    else string_from_ptr res (Unsigned.Size_t.to_int (!@ res_size))

  let get_value_raw =
    foreign
      "rocksdb_iter_value"
      (t @-> ptr size_t @-> returning (ptr char))

  let get_value t =
    let res_size = allocate size_t (Unsigned.Size_t.of_int 0) in
    let res = get_value_raw t res_size in
    if (to_voidp res) = null
    then failwith (Printf.sprintf
                     "could not get key, is_valid=%b" (is_valid t))
    else string_from_ptr res (Unsigned.Size_t.to_int (!@ res_size))

  let get_error_raw =
    foreign
      "rocksdb_iter_get_error"
      (t @-> ptr string_opt @-> returning void)

  let get_error t =
    let err_pointer = allocate string_opt None in
    get_error_raw t err_pointer;
    !@ err_pointer

end
