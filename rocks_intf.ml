include Rocks_options

module type ITERATOR = sig
  exception InvalidIterator

  type db
  type t

  val create : ?opts:ReadOptions.t -> db -> t
  val with_t : ?opts:ReadOptions.t -> db -> f:(t -> 'a) -> 'a

  val is_valid : t -> bool

  val seek_to_first : t -> unit
  val seek_to_last : t -> unit

  val seek : ?pos:int -> ?len:int -> t -> Cstruct.buffer -> unit
  val seek_string : ?pos:int -> ?len:int -> t -> string -> unit
  val seek_cstruct : t -> Cstruct.t -> unit

  val next : t -> unit
  val prev : t -> unit

  val get_key_string : t -> string
  (** returned buffer is only valid as long as [t] is not modified *)
  val get_key : t -> Cstruct.buffer
  val get_key_cstruct : t -> Cstruct.t

  val get_value_string : t -> string
  (** returned buffer is only valid as long as [t] is not modified *)
  val get_value : t -> Cstruct.buffer
  val get_value_cstruct : t -> Cstruct.t

  val get_error : t -> string option

  val fold : ?from:Cstruct.t -> t -> init:'a -> f:(key:Cstruct.t -> data:Cstruct.t -> 'a -> 'a) -> 'a
  val fold_right : ?from:Cstruct.t -> t -> init:'a -> f:(key:Cstruct.t -> data:Cstruct.t -> 'a -> 'a) -> 'a
  val iteri : ?from:Cstruct.t -> t -> f:(key:Cstruct.t -> data:Cstruct.t -> unit) -> unit
  val rev_iteri : ?from:Cstruct.t -> t -> f:(key:Cstruct.t -> data:Cstruct.t -> unit) -> unit
end

module type ROCKS = sig
  type t
  type batch

  val open_db : ?opts:Options.t -> string -> t
  val with_db : ?opts:Options.t -> string -> f:(t -> 'a) -> 'a
  val close : t -> unit

  val get : ?pos:int -> ?len:int -> ?opts:ReadOptions.t -> t -> Cstruct.buffer -> Cstruct.buffer option
  val get_string : ?pos:int -> ?len:int -> ?opts:ReadOptions.t -> t -> string -> string option
  val get_cstruct : ?opts:ReadOptions.t -> t -> Cstruct.t -> Cstruct.t option

  val put : ?key_pos:int -> ?key_len:int -> ?value_pos:int -> ?value_len:int -> ?opts:WriteOptions.t -> t -> Cstruct.buffer -> Cstruct.buffer -> unit
  val put_string : ?key_pos:int -> ?key_len:int -> ?value_pos:int -> ?value_len:int -> ?opts:WriteOptions.t -> t -> string -> string -> unit
  val put_cstruct : ?opts:WriteOptions.t -> t -> Cstruct.t -> Cstruct.t -> unit

  val delete : ?pos:int -> ?len:int -> ?opts:WriteOptions.t -> t -> Cstruct.buffer -> unit
  val delete_string : ?pos:int -> ?len:int -> ?opts:WriteOptions.t -> t -> string -> unit
  val delete_cstruct : ?opts:WriteOptions.t -> t -> Cstruct.t -> unit

  val write : ?opts:WriteOptions.t -> t -> batch -> unit

  val flush : ?opts:FlushOptions.t -> t -> unit

  val fold : ?opts:ReadOptions.t -> ?from:Cstruct.t -> t -> init:'a -> f:(key:Cstruct.t -> data:Cstruct.t -> 'a -> 'a) -> 'a
  val fold_right : ?opts:ReadOptions.t -> ?from:Cstruct.t -> t -> init:'a -> f:(key:Cstruct.t -> data:Cstruct.t -> 'a -> 'a) -> 'a
  val iteri : ?opts:ReadOptions.t -> ?from:Cstruct.t -> t -> f:(key:Cstruct.t -> data:Cstruct.t -> unit) -> unit
  val rev_iteri : ?opts:ReadOptions.t -> ?from:Cstruct.t -> t -> f:(key:Cstruct.t -> data:Cstruct.t -> unit) -> unit
end
