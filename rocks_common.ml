open Ctypes
open Foreign

module Views = struct
  open Unsigned

  let bool_to_int =
    view
      ~read:(fun i -> i <> 0)
      ~write:(function true -> 1 | false -> 0)
      int

  let bool_to_uchar =
    view
      ~read:(fun u -> u <> UChar.zero)
      ~write:(function true -> UChar.one | false -> UChar.zero)
      uchar

  let int_to_size_t =
    view
      ~read:Size_t.to_int
      ~write:Size_t.of_int
      size_t

  let int_to_uint_t =
    view
      ~read:UInt.to_int
      ~write:UInt.of_int
      uint

  let int_to_uint32_t =
    view
      ~read:UInt32.to_int
      ~write:UInt32.of_int
      uint32_t

  let int_to_uint64_t =
    view
      ~read:UInt64.to_int
      ~write:UInt64.of_int
      uint64_t
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
    Gc.finalise destroy t;
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
