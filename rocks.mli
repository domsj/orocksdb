exception OperationOnInvalidObject

module Views :
  sig
    val bool_to_int : bool Ctypes.typ
    val bool_to_uchar : bool Ctypes.typ
    val int_to_size_t : int Ctypes.typ
  end

module Cache :
  sig
    type t
    val create_no_gc : int -> t
    val destroy : t -> unit
    val with_t : int -> (t -> 'a) -> 'a
  end

module BlockBasedTableOptions :
  sig
    type t
    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create_gc : unit -> t
    val with_t : (t -> 'a) -> 'a

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

module Options :
  sig
    type t

    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create_gc : unit -> t
    val with_t : (t -> 'a) -> 'a

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
    val set_max_write_buffer_number_to_maintain :
      t -> int -> unit
    val set_max_background_compactions : t -> int -> unit
    val set_max_background_flushes : t -> int -> unit
    val set_max_log_file_size : t -> int -> unit
    val set_log_file_time_to_roll : t -> int -> unit
    val set_keep_log_file_num : t -> int -> unit
    val set_recycle_log_file_num : t -> int -> unit
    val set_soft_rate_limit : t -> float -> unit
    val set_hard_rate_limit : t -> float -> unit
    val set_rate_limit_delay_max_milliseconds :
      t -> int -> unit
    val set_max_manifest_file_size : t -> int -> unit
    val set_table_cache_numshardbits : t -> int -> unit
    val set_table_cache_remove_scan_count_limit :
      t -> int -> unit
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
    val set_max_sequential_skip_in_iterations :
      t -> int -> unit
    val set_disable_data_sync : t -> int -> unit
    val set_disable_auto_compactions : t -> int -> unit
    val set_delete_obsolete_files_period_micros :
      t -> int -> unit
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
module WriteOptions :
  sig
    type t

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
    type t

    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create_gc : unit -> t
    val with_t : (t -> 'a) -> 'a
  end
module FlushOptions :
  sig
    type t

    val type_name : string
    val create_no_gc : unit -> t
    val destroy : t -> unit
    val create_gc : unit -> t
    val with_t : (t -> 'a) -> 'a

    val set_wait : t -> bool -> unit
  end
module WriteBatch :
  sig
    type t

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
    type t

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

    val delete_slice : t -> WriteOptions.t ->
      string -> int -> int -> unit
    val delete : t -> WriteOptions.t -> string -> unit

    val write : t -> WriteOptions.t -> WriteBatch.t -> unit

    val flush : t -> FlushOptions.t -> unit
  end
module Iterator :
  sig
    type t

    exception InvalidIterator

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
