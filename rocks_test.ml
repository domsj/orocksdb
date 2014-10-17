open Ctypes
open Rocks

let () =
  let options = Options.create () in
  Options.set_create_if_missing options true;
  let err_pointer = allocate string_opt None in
  let assert_no_error () =
    match !@ err_pointer with
    | None -> ()
    | Some err -> failwith err in
  let db =
    RocksDb.open_db
      options
      "aname"
      err_pointer
  in
  assert_no_error ();
  let write_options = WriteOptions.create () in
  RocksDb.put
    db write_options
    (ocaml_string_start "mykey") (Unsigned.Size_t.of_int 5)
    (ocaml_string_start "avalue") (Unsigned.Size_t.of_int 6)
    err_pointer;
  assert_no_error ();
  let read key =
    let read_options = ReadOptions.create () in
    let res_size = allocate size_t (Unsigned.Size_t.of_int 8) in
    let res =
      RocksDb.get
        db read_options
        (ocaml_string_start key) (Unsigned.Size_t.of_int (String.length key))
        res_size err_pointer in
    if raw_address_of_ptr (to_voidp res) = 0L
    then None
    else begin
      let res' = string_from_ptr res (Unsigned.Size_t.to_int (!@ res_size)) in
      Some res'
    end in
  let show_string_option = [%derive.Show: string option] in
  print_endline (show_string_option (read "mykey"));
  print_endline (show_string_option (read "mykey2"));
  RocksDb.close db
