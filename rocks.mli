module Views :
  sig
    val bool_to_int : bool Ctypes.typ
    val bool_to_uchar : bool Ctypes.typ
    val int_to_size_t : int Ctypes.typ
  end

module Options :
  sig
    type t = unit Ctypes.ptr
    val t : t Ctypes.typ

    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create_gc : unit -> t
    val with_t : (t -> 'a) -> 'a

    val set_create_if_missing : t -> bool -> unit
    val set_use_fsync : t -> bool -> unit
  end
module WriteOptions :
  sig
    type t = unit Ctypes.ptr
    val t : t Ctypes.typ

    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create_gc : unit -> t
    val with_t : (t -> 'a) -> 'a

    val set_disable_WAL : t -> bool -> unit
    val set_sync : t -> bool -> unit
  end
module ReadOptions :
  sig
    type t = unit Ctypes.ptr
    val t : t Ctypes.typ

    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create_gc : unit -> t
    val with_t : (t -> 'a) -> 'a
  end
module WriteBatch :
  sig
    type t = unit Ctypes.ptr
    val t : t Ctypes.typ

    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create_gc : unit -> t
    val with_t : (t -> 'a) -> 'a

    val clear : t -> unit
    val count : t -> int

    val put_slice : t ->
      string -> int -> int ->
      string -> int -> int -> unit
    val put : t ->
      string ->
      string -> unit
    val delete_slice : t -> string -> int -> int -> unit
    val delete : t -> string -> unit
  end
module RocksDb :
  sig
    type t = unit Ctypes.ptr
    val t : t Ctypes.typ

    val open_db : Options.t -> string -> t
    val close : t -> unit

    val get_slice : t -> ReadOptions.t ->
      string -> int -> int ->
      string option
    val get : t -> ReadOptions.t -> string -> string option
    val put_slice : t -> WriteOptions.t ->
      string -> int -> int ->
      string -> int -> int -> unit
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
    val with_t : RocksDb.t -> ReadOptions.t -> (t -> 'a) -> 'a

    val is_valid : t -> bool

    val seek_to_first : t -> unit
    val seek_to_last : t -> unit

    val seek_slice : t -> string -> int -> int -> unit
    val seek : t -> string -> unit

    val next : t -> unit
    val prev : t -> unit

    val get_key : t -> string

    val get_value : t -> string

    val get_error_raw : t -> string option Ctypes.ptr -> unit
    val get_error : t -> string option
  end
