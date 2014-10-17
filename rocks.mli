module Options :
  sig
    type t = unit Ctypes.ptr
    val t : t Ctypes.typ

    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create : unit -> t

    val set_create_if_missing : t -> bool -> unit
  end
module WriteOptions :
  sig
    type t = unit Ctypes.ptr
    val t : t Ctypes.typ

    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create : unit -> t

    val set_disable_WAL : t -> bool -> unit
  end
module ReadOptions :
  sig
    type t = unit Ctypes.ptr
    val t : t Ctypes.typ

    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create : unit -> t
  end
module WriteBatch :
  sig
    type t = unit Ctypes.ptr
    val t : t Ctypes.typ

    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create : unit -> t

    val clear : t -> unit
    val count : t -> int

    val put_raw :
      t ->
      char Ctypes.ptr ->
      Unsigned.size_t -> char Ctypes.ptr -> Unsigned.size_t -> unit
    val put : t -> string -> string -> unit

    val delete_raw : t -> char Ctypes.ptr -> Unsigned.size_t -> unit
    val delete : t -> string -> unit
  end
module RocksDb :
  sig
    type t = unit Ctypes.ptr
    val t : t Ctypes.typ

    val open_db : Options.t -> string -> t
    val close : t -> unit

    val get : t -> ReadOptions.t -> string -> string option
    val put : t -> WriteOptions.t -> string -> string -> unit
    val write : t -> WriteOptions.t -> WriteBatch.t -> unit
  end
module Iterator :
  sig
    type t = unit Ctypes.ptr
    val t : t Ctypes.typ

    val create_no_gc : RocksDb.t -> ReadOptions.t -> t
    val destroy : t -> unit
    val create : RocksDb.t -> ReadOptions.t -> t

    val is_valid : t -> bool

    val seek_to_first : t -> unit
    val seek_to_last : t -> unit

    val seek_raw : t -> char Ctypes.ptr -> Unsigned.size_t -> unit
    val seek : t -> string -> unit

    val next : t -> unit
    val prev : t -> unit

    val get_key_raw : t -> Unsigned.size_t Ctypes.ptr -> char Ctypes.ptr
    val get_key : t -> string

    val get_value_raw : t -> Unsigned.size_t Ctypes.ptr -> char Ctypes.ptr
    val get_value : t -> string

    val get_error_raw : t -> string option Ctypes.ptr -> unit
    val get_error : t -> string option
  end
