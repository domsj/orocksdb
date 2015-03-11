open Ctypes
open Foreign

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

  let int_to_size_t =
    view
      ~read:(fun size -> Unsigned.Size_t.to_int size)
      ~write:(fun i -> Unsigned.Size_t.of_int i)
      size_t
end

let free =
  foreign
    "free"
    (ptr void @-> returning void)

module type RocksType = sig
  val name : string
end

type t' =  {
  ptr : unit ptr;
  mutable valid : bool;
}

exception OperationOnInvalidObject

let t : t' typ =
  view
    ~read:(fun ptr -> { ptr; valid = true; })
    ~write:(
      fun { ptr; valid; } ->
        if valid
        then ptr
        else raise OperationOnInvalidObject)
    (ptr void)

module CreateConstructors_(T : RocksType) = struct
  type t = t'
  let t = t

  let type_name = T.name

  let create_no_gc =
    foreign
      ("rocksdb_" ^ T.name ^ "_create")
      (void @-> returning t)

  let destroy =
    let inner =
      foreign
        ("rocksdb_" ^ T.name ^ "_destroy")
        (t @-> returning void) in
    fun t ->
      inner t;
      t.valid <- false

  let create_gc () =
    let t = create_no_gc () in
    Gc.finalise (fun t -> destroy t) t;
    t

  let with_t f =
    let t = create_no_gc () in
    try
      let res = f t in
      destroy t;
      res
    with exn ->
      destroy t;
      raise exn

  let create_setter property_name property_typ =
    foreign
      ("rocksdb_" ^ type_name ^ "_" ^ property_name)
      (t @-> property_typ @-> returning void)
end

module Options = struct
  module C = CreateConstructors_(struct let name = "options" end)
  include C

  let set_create_if_missing = create_setter "set_create_if_missing" Views.bool_to_uchar
  let set_use_fsync = create_setter "set_use_fsync" Views.bool_to_int
end

module WriteOptions = struct
  module C = CreateConstructors_(struct let name = "writeoptions" end)
  include C

  let set_disable_WAL = create_setter "disable_WAL" Views.bool_to_int
  let set_sync = create_setter "set_sync" Views.bool_to_uchar
end

module ReadOptions = struct
  module C = CreateConstructors_(struct let name = "readoptions" end)
  include C
end

module FlushOptions = struct
  module C = CreateConstructors_(struct let name = "flushoptions" end)
  include C

  let set_wait = create_setter "set_wait" Views.bool_to_uchar
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
       ocaml_string @-> Views.int_to_size_t @->
       ocaml_string @-> Views.int_to_size_t @->
       returning void)
  let put_slice batch key k_off k_len value v_off v_len =
    put_raw
      batch
      (ocaml_string_start key +@ k_off) k_len
      (ocaml_string_start value +@ v_off) v_len
  let put batch key value =
    put_slice
      batch
      key 0 (String.length key)
      value 0 (String.length value)

  let delete_raw =
    foreign
      "rocksdb_writebatch_delete"
      (t @->
       ocaml_string @-> Views.int_to_size_t @->
       returning void)

  let delete_slice batch key k_off k_len =
    delete_raw batch (ocaml_string_start key +@ k_off) k_len
  let delete batch key =
    delete_slice batch key 0 (String.length key)
end

module RocksDb = struct
  type t = t'
  let t = t

  let returning_error typ = ptr string_opt @-> returning typ

  let with_err_pointer f =
    let err_pointer = allocate string_opt None in
    let res = f err_pointer in
    match !@ err_pointer with
    | None ->
      res
    | Some err ->
      free (to_voidp err_pointer);
      failwith err

  let open_db =
    let inner =
      foreign
        "rocksdb_open"
        (Options.t @-> string @-> ptr string_opt @-> returning t) in
    fun options name -> with_err_pointer (inner options name)

  let close =
    let inner =
      foreign
        "rocksdb_close"
        (t @-> returning void)
    in
    fun t ->
      inner t;
      t.valid <- false

  let put_slice =
    let inner =
      foreign
        "rocksdb_put"
        (t @-> WriteOptions.t @->
         ocaml_string @-> Views.int_to_size_t @->
         ocaml_string @-> Views.int_to_size_t @->
         returning_error void) in
    fun t wo key k_off k_len value v_off v_len ->
      with_err_pointer
        (inner
           t wo 
           (ocaml_string_start key +@ k_off) k_len
           (ocaml_string_start value +@ v_off) v_len)

  let put t wo key value =
    put_slice
      t wo
      key 0 (String.length key)
      value 0 (String.length value)

  let delete_slice =
    let inner =
      foreign
        "rocksdb_delete"
        (t @-> WriteOptions.t @->
         ocaml_string @-> Views.int_to_size_t @->
         returning_error void) in
    fun t wo key k_off k_len ->
      with_err_pointer
        (inner
          t wo
          (ocaml_string_start key +@ k_off) k_len)

  let delete t wo key =
    delete_slice
      t wo
      key 0 (String.length key)

  let write =
    let inner =
      foreign
        "rocksdb_write"
        (t @-> WriteOptions.t @-> WriteBatch.t @->
         returning_error void) in
    fun t options batch -> with_err_pointer (inner t options batch)

  let get_slice =
    let inner =
      foreign
        "rocksdb_get"
        (t @-> ReadOptions.t @->
         ocaml_string @-> Views.int_to_size_t @-> ptr Views.int_to_size_t @->
         returning_error (ptr char)) in
    fun t options key k_off k_len->
      let res_size = allocate Views.int_to_size_t 0 in
      let res =
        with_err_pointer
          (inner
             t options
             (ocaml_string_start key +@ k_off) k_len
             res_size) in
      if (to_voidp res) = null
      then None
      else begin
        let res' = string_from_ptr res (!@ res_size) in
        free (to_voidp res);
        Some res'
      end

  let get t o k = get_slice t o k 0 (String.length k)

  let flush t' o =
    let inner =
      foreign
        "rocksdb_flush"
        (t @-> FlushOptions.t @-> returning_error void)
    in
    with_err_pointer
      (inner t' o)
end

module Iterator = struct
  type t = t'
  let t = t

  exception InvalidIterator

  let create_no_gc =
    foreign
      "rocksdb_create_iterator"
      (RocksDb.t @-> ReadOptions.t @-> returning t)

  let destroy =
    let inner =
      foreign
        "rocksdb_iter_destroy"
        (t @-> returning void)
    in
    fun t ->
      inner t;
      t.valid <- false

  let create db read_options =
    let t = create_no_gc db read_options in
    Gc.finalise (fun t -> destroy t) t;
    t

  let with_t db read_options f =
    let t = create_no_gc db read_options in
    try
      let res = f t in
      destroy t;
      res
    with exn ->
      destroy t;
      raise exn

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
      (t @-> ocaml_string @-> Views.int_to_size_t @-> returning void)

  let seek_slice t key k_off k_len =
    seek_raw t (ocaml_string_start key +@ k_off) k_len

  let seek t key = seek_slice t key 0 (String.length key)

  let next =
    foreign
      "rocksdb_iter_next"
      (t @-> returning void)

  let prev =
    foreign
      "rocksdb_iter_prev"
      (t @-> returning void)

  let get_key_raw =
    let inner =
      foreign
        "rocksdb_iter_key"
        (t @-> ptr Views.int_to_size_t @-> returning (ptr char))
    in
    fun t size ->
      if is_valid t
      then inner t size
      else raise InvalidIterator

  let get_key t =
    let res_size = allocate Views.int_to_size_t 0 in
    let res = get_key_raw t res_size in
    if (to_voidp res) = null
    then failwith (Printf.sprintf
                     "could not get key, is_valid=%b" (is_valid t))
    else string_from_ptr res (!@ res_size)

  let get_value_raw =
    let inner =
      foreign
        "rocksdb_iter_value"
        (t @-> ptr Views.int_to_size_t @-> returning (ptr char))
    in
    fun t size ->
      if is_valid t
      then inner t size
      else raise InvalidIterator

  let get_value t =
    let res_size = allocate Views.int_to_size_t 0 in
    let res = get_value_raw t res_size in
    if (to_voidp res) = null
    then failwith (Printf.sprintf
                     "could not get key, is_valid=%b" (is_valid t))
    else string_from_ptr res (!@ res_size)

  let get_error_raw =
    foreign
      "rocksdb_iter_get_error"
      (t @-> ptr string_opt @-> returning void)

  let get_error t =
    let err_pointer = allocate string_opt None in
    get_error_raw t err_pointer;
    let res = !@ err_pointer in
    let () =
      if res <> None
      then free (to_voidp err_pointer)
    in
    res

end
