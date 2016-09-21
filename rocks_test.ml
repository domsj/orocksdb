open Rocks

let main () =
  let () =
    let open Version in
    Printf.printf "version (%i,%i,%i,%S)\n%!" major minor patch git_revision
  in
  let open_opts = Options.create_gc () in
  Options.set_create_if_missing open_opts true;

  let db = RocksDb.open_db ~opts:open_opts "aname" in

  let () =
    try let _ = RocksDb.open_db ~opts:open_opts "/dev/jvioxidsod" in
        ()
    with _ -> ()
  in

  let write_opts = WriteOptions.create_gc () in
  RocksDb.put_cstruct ~opts:write_opts db (Cstruct.of_string "mykey") (Cstruct.of_string "avalue");
  let read_opts = ReadOptions.create_gc () in
  let read key = RocksDb.get_cstruct ~opts:read_opts db key in
  let print_cstruct_option x =
    print_endline
      (match x with
       | Some v -> "Some(" ^ Cstruct.to_string v ^ ")"
       | None -> "None") in
  print_cstruct_option (read @@ Cstruct.of_string "mykey");
  print_cstruct_option (read @@ Cstruct.of_string "mykey2");
  RocksDb.close db

let () =
  try main ();
      Gc.full_major ()
  with exn ->
    Gc.full_major ();
    raise exn
