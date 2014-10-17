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
  let show_string_option = [%derive.Show: string option] in
  print_endline (show_string_option (read "mykey"));
  print_endline (show_string_option (read "mykey2"));
  RocksDb.close db
