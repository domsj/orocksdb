exception OperationOnInvalidObject

module Views : sig
  val bool_to_int : bool Ctypes.typ
  val bool_to_uchar : bool Ctypes.typ
  val int_to_size_t : int Ctypes.typ
end

module Cache : sig
  type nonrec t = Rocks_common.t
  val t : Rocks_common.t Ctypes.typ
  val get_pointer : Rocks_common.t -> unit Ctypes.ptr
  val create_no_gc : int -> Rocks_common.t
  val destroy : Rocks_common.t -> unit
  val with_t : int -> (Rocks_common.t -> 'a) -> 'a
end

module BlockBasedTableOptions : sig
  include Rocks_common.S

  val set_block_size : t -> int -> unit
  val set_block_size_deviation : t -> int -> unit
  val set_block_restart_interval : t -> int -> unit
  val set_no_block_cache : t -> bool -> unit
  val set_block_cache : t -> Cache.t -> unit
  val set_block_cache_compressed : t -> Cache.t -> unit
  val set_whole_key_filtering : t -> bool -> unit
  val set_format_version : t -> int -> unit
  module IndexType :
  sig type t
    val binary_search : t
    val hash_search : t
  end
  val set_index_type : t -> IndexType.t -> unit
  val set_hash_index_allow_collision : t -> bool -> unit
  val set_cache_index_and_filter_blocks : t -> bool -> unit
end

module Options : sig
  include Rocks_common.S

  val increase_parallelism : t -> int -> unit
  val optimize_for_point_lookup : t -> int -> unit
  val optimize_level_style_compaction : t -> int -> unit
  val optimize_universal_style_compaction : t -> int -> unit
  val set_create_if_missing : t -> bool -> unit
  val set_create_missing_column_families : t -> bool -> unit
  val set_error_if_exists : t -> bool -> unit
  val set_paranoid_checks : t -> bool -> unit
  val set_write_buffer_size : t -> int -> unit
  val set_max_open_files : t -> int -> unit
  val set_max_total_wal_size : t -> int -> unit
  val set_max_write_buffer_number : t -> int -> unit
  val set_min_write_buffer_number_to_merge : t -> int -> unit
  val set_max_write_buffer_number_to_maintain : t -> int -> unit
  val set_max_background_compactions : t -> int -> unit
  val set_max_background_flushes : t -> int -> unit
  val set_max_log_file_size : t -> int -> unit
  val set_log_file_time_to_roll : t -> int -> unit
  val set_keep_log_file_num : t -> int -> unit
  val set_recycle_log_file_num : t -> int -> unit
  val set_soft_rate_limit : t -> float -> unit
  val set_hard_rate_limit : t -> float -> unit
  val set_rate_limit_delay_max_milliseconds : t -> int -> unit
  val set_max_manifest_file_size : t -> int -> unit
  val set_table_cache_numshardbits : t -> int -> unit
  val set_table_cache_remove_scan_count_limit : t -> int -> unit
  val set_arena_block_size : t -> int -> unit
  val set_use_fsync : t -> bool -> unit
  val set_WAL_ttl_seconds : t -> int -> unit
  val set_WAL_size_limit_MB : t -> int -> unit
  val set_manifest_preallocation_size : t -> int -> unit
  val set_purge_redundant_kvs_while_flush : t -> bool -> unit
  val set_allow_os_buffer : t -> bool -> unit
  val set_allow_mmap_reads : t -> bool -> unit
  val set_allow_mmap_writes : t -> bool -> unit
  val set_is_fd_close_on_exec : t -> bool -> unit
  val set_skip_log_error_on_recovery : t -> bool -> unit
  val set_stats_dump_period_sec : t -> int -> unit
  val set_advise_random_on_open : t -> bool -> unit
  val set_access_hint_on_compaction_start : t -> int -> unit
  val set_use_adaptive_mutex : t -> bool -> unit
  val set_bytes_per_sync : t -> int -> unit
  val set_verify_checksums_in_compaction : t -> bool -> unit
  val set_filter_deletes : t -> bool -> unit
  val set_max_sequential_skip_in_iterations : t -> int -> unit
  val set_disable_data_sync : t -> int -> unit
  val set_disable_auto_compactions : t -> int -> unit
  val set_delete_obsolete_files_period_micros : t -> int -> unit
  val set_source_compaction_factor : t -> int -> unit
  val set_min_level_to_compress : t -> int -> unit
  val set_memtable_prefix_bloom_bits : t -> int -> unit
  val set_memtable_prefix_bloom_probes : t -> int -> unit
  val set_max_successive_merges : t -> int -> unit
  val set_min_partial_merge_operands : t -> int -> unit
  val set_bloom_locality : t -> int -> unit
  val set_inplace_update_support : t -> bool -> unit
  val set_inplace_update_num_locks : t -> int -> unit

  val set_block_based_table_factory : t -> BlockBasedTableOptions.t -> unit
end

module WriteOptions : sig
  include Rocks_common.S

  val set_disable_WAL : t -> bool -> unit
  val set_sync : t -> bool -> unit
end

module ReadOptions : Rocks_common.S

module FlushOptions : sig
  include Rocks_common.S

  val set_wait : t -> bool -> unit
end

module WriteBatch : sig
  include Rocks_common.S

  val clear : t -> unit
  val count : t -> int

  val put : ?key_pos:int -> ?key_len:int -> ?value_pos:int -> ?value_len:int -> t -> Cstruct.buffer -> Cstruct.buffer -> unit
  val put_cstruct : t -> Cstruct.t -> Cstruct.t -> unit

  val delete : ?pos:int -> ?len:int -> t -> Cstruct.buffer -> unit
  val delete_cstruct : t -> Cstruct.t -> unit
end

module RocksDb : sig
  type t
  val get_pointer : t -> unit Ctypes.ptr

  val open_db : ?opts:Options.t -> string -> t
  val close : t -> unit

  val get : ?opts:ReadOptions.t -> ?pos:int -> ?len:int -> t -> Cstruct.buffer -> Cstruct.buffer option
  val get_cstruct : ?opts:ReadOptions.t -> t -> Cstruct.t -> Cstruct.t option

  val put : ?key_pos:int -> ?key_len:int -> ?value_pos:int -> ?value_len:int -> ?opts:WriteOptions.t -> t -> Cstruct.buffer -> Cstruct.buffer -> unit
  val put_cstruct : ?opts:WriteOptions.t -> t -> Cstruct.t -> Cstruct.t -> unit

  val delete : ?pos:int -> ?len:int -> ?opts:WriteOptions.t -> t -> Cstruct.buffer -> unit
  val delete_cstruct : ?opts:WriteOptions.t -> t -> Cstruct.t -> unit

  val write : ?opts:WriteOptions.t -> t -> WriteBatch.t -> unit

  val flush : t -> FlushOptions.t -> unit
end

module Iterator : sig
  exception InvalidIterator

  type nonrec t = Rocks_common.t
  val t : Rocks_common.t Ctypes.typ
  val get_pointer : Rocks_common.t -> unit Ctypes.ptr
  val create_no_gc : RocksDb.t -> ReadOptions.t -> t
  val destroy : Rocks_common.t -> unit
  val with_t : RocksDb.t -> ReadOptions.t -> (t -> 'a) -> 'a

  val is_valid : t -> bool

  val seek_to_first : t -> unit
  val seek_to_last : t -> unit

  val seek : ?pos:int -> ?len:int -> t -> Cstruct.buffer -> unit
  val seek_cstruct : t -> Cstruct.t -> unit

  val next : t -> unit
  val prev : t -> unit

  val get_key : t -> Cstruct.buffer
  val get_key_cstruct : t -> Cstruct.t

  val get_value : t -> Cstruct.buffer
  val get_value_cstruct : t -> Cstruct.t

  val get_error : t -> string option
end

module Version : sig
  val major : int
  val minor : int
  val patch : int
  val git_revision : string
  val summary : int * int * int * string
end
