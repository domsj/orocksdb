open Rocks

let () =
  let options = Options.create () in
  Options.set_create_if_missing options true;

  let db =
    RocksDb.open_db
      options
      "aname"
  in

  let write_options = WriteOptions.create () in
  RocksDb.put db write_options "mykey" "avalue";
  let read_options = ReadOptions.create () in
  let read key = RocksDb.get db read_options key in
  let print_string_option x =
    print_endline
      (match x with
       | Some v -> "Some(" ^ v ^ ")"
       | None -> "None") in
  print_string_option (read "mykey");
  print_string_option (read "mykey2");
  RocksDb.close db
