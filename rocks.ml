open Ctypes
open Foreign
open Rocks_common

module Views = Views

include Rocks_options

exception OperationOnInvalidObject = Rocks_common.OperationOnInvalidObject

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
       ptr char @-> Views.int_to_size_t @->
       ptr char @-> Views.int_to_size_t @-> returning void)

  let put_cstruct batch key value =
    put_raw batch
      (bigarray_start array1 @@ Cstruct.to_bigarray key) key.len
      (bigarray_start array1 @@ Cstruct.to_bigarray value) value.len

  let put ?key_pos ?key_len ?value_pos ?value_len batch key value =
    let key = Cstruct.of_bigarray ?off:key_pos ?len:key_len key in
    let value = Cstruct.of_bigarray ?off:value_pos ?len:value_len value in
    put_cstruct batch key value

  let delete_raw =
    foreign
      "rocksdb_writebatch_delete"
      (t @-> ptr char @-> Views.int_to_size_t @-> returning void)

  let delete_cstruct batch key =
    delete_raw batch (bigarray_start array1 @@ Cstruct.to_bigarray key) key.len

  let delete ?pos ?len batch key =
    let key = Cstruct.of_bigarray ?off:pos ?len key in
    delete_cstruct batch key
end

module RocksDb = struct
  type nonrec t = t
  let t = t

  let get_pointer = get_pointer

  let returning_error typ = ptr string_opt @-> returning typ

  let with_err_pointer f =
    let err_pointer = allocate string_opt None in
    let res = f err_pointer in
    match !@ err_pointer with
    | None -> res
    | Some err -> failwith err

  let open_db_raw =
    foreign
      "rocksdb_open"
      (Options.t @-> string @-> ptr string_opt @-> returning t)

  let open_db ?opts name =
    match opts with
    | None -> Options.with_t (fun options -> with_err_pointer (open_db_raw options name))
    | Some opts -> with_err_pointer (open_db_raw opts name)

  let close =
    let inner =
      foreign
        "rocksdb_close"
        (t @-> returning void)
    in
    fun t ->
      inner t;
      t.valid <- false

  let put_raw =
    foreign
      "rocksdb_put"
      (t @-> WriteOptions.t @->
       ptr char @-> Views.int_to_size_t @->
       ptr char @-> Views.int_to_size_t @->
       returning_error void)

  let put_cstruct ?opts t key value =
    let inner opts = with_err_pointer begin
        put_raw t opts
          (bigarray_start array1 @@ Cstruct.to_bigarray key) key.len
          (bigarray_start array1 @@ Cstruct.to_bigarray value) value.len
      end
    in
    match opts with
    | None -> WriteOptions.with_t inner
    | Some opts -> inner opts

  let put ?key_pos ?key_len ?value_pos ?value_len ?opts t key value =
    let key = Cstruct.of_bigarray ?off:key_pos ?len:key_len key in
    let value = Cstruct.of_bigarray ?off:value_pos ?len:value_len value in
    put_cstruct ?opts t key value

  let delete_raw =
    foreign
      "rocksdb_delete"
      (t @-> WriteOptions.t @->
       ptr char @-> Views.int_to_size_t @->
       returning_error void)

  let delete_cstruct ?opts t key =
    let inner opts =
      with_err_pointer (delete_raw t opts (bigarray_start array1 @@ Cstruct.to_bigarray key) key.len) in
    match opts with
    | None -> WriteOptions.with_t inner
    | Some opts -> inner opts

  let delete ?pos ?len ?opts t key =
    let key = Cstruct.of_bigarray ?off:pos ?len key in
    delete_cstruct ?opts t key

  let write_raw =
    foreign
      "rocksdb_write"
      (t @-> WriteOptions.t @-> WriteBatch.t @->
       returning_error void)

  let write ?opts t wb =
    let inner opts = with_err_pointer (write_raw t opts wb) in
    match opts with
    | None -> WriteOptions.with_t inner
    | Some opts -> with_err_pointer (write_raw t opts wb)

  let get_raw =
    foreign
      "rocksdb_get"
      (t @-> ReadOptions.t @->
       ptr char @-> Views.int_to_size_t @-> ptr Views.int_to_size_t @->
       returning_error (ptr char))

  let get_cstruct ?opts t key =
    let inner opts =
      let res_size = allocate Views.int_to_size_t 0 in
      let res = with_err_pointer (get_raw t opts (bigarray_start array1 @@ Cstruct.to_bigarray key) key.len res_size) in
      if (to_voidp res) = null
      then None
      else begin
        let res' = bigarray_of_ptr array1 1 Bigarray.char res |> Cstruct.of_bigarray in
        Gc.finalise (fun res -> free (to_voidp res)) res;
        Some res'
      end
    in
    match opts with
    | Some opts -> inner opts
    | None -> ReadOptions.with_t inner

  let get ?opts ?pos ?len t key =
    match get_cstruct ?opts t @@ Cstruct.of_bigarray ?off:pos ?len key with
    | None -> None
    | Some res -> Some (Cstruct.to_bigarray res)

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
  type nonrec t = t
  let t = t

  let get_pointer = get_pointer

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
    Gc.finalise destroy t;
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
      (t @-> ptr char @-> Views.int_to_size_t @-> returning void)

  let seek_cstruct t key = seek_raw t (bigarray_start array1 @@ Cstruct.to_bigarray key) key.len

  let seek ?pos ?len t key =
    let key = Cstruct.of_bigarray ?off:pos ?len key in
    seek_cstruct t key

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

  let get_key_cstruct t =
    let res_size = allocate Views.int_to_size_t 0 in
    let res = get_key_raw t res_size in
    if (to_voidp res) = null
    then failwith (Printf.sprintf "could not get key, is_valid=%b" (is_valid t))
    else bigarray_of_ptr array1 1 Bigarray.char res |> Cstruct.of_bigarray

  let get_key t = get_key_cstruct t |> Cstruct.to_bigarray

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

  let get_value_cstruct t =
    let res_size = allocate Views.int_to_size_t 0 in
    let res = get_value_raw t res_size in
    if (to_voidp res) = null
    then failwith (Printf.sprintf "could not get value, is_valid=%b" (is_valid t))
    else bigarray_of_ptr array1 1 Bigarray.char res |> Cstruct.of_bigarray

  let get_value t = get_value_cstruct t |> Cstruct.to_bigarray

  let get_error_raw =
    foreign
      "rocksdb_iter_get_error"
      (t @-> ptr string_opt @-> returning void)

  let get_error t =
    let err_pointer = allocate string_opt None in
    get_error_raw t err_pointer;
    !@err_pointer

end

module Version = Rocks_version
