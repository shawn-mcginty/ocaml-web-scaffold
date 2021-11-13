let add_new_tokens_to_env key_token val_token =
  let () = print_endline (Printf.sprintf "loading env var: %s" key_token) in
  match Sys.getenv_opt key_token with
  | Some _ -> ()
  | None -> Unix.putenv key_token val_token

let rec read_lines ?(lines = []) ic =
  try
    let line = input_line ic in
    let new_lines = line :: lines in
    read_lines ~lines:new_lines ic
  with e -> (
    match e with
    | End_of_file ->
        close_in ic;
        lines
    | _ ->
        close_in_noerr ic;
        raise e)

let load ?(path = ".env") () =
  let full_path = Printf.sprintf "%s/%s" (Sys.getcwd ()) path in
  let () = print_endline ("Check if .env exists " ^ full_path) in
  let exists = Sys.file_exists full_path in
  match exists with
  | false ->
      let () = print_endline "It don't." in
      Lwt.return_unit
  | true ->
      let () = print_endline "It exists try opening it" in
      let ic = open_in full_path in
      let lines = read_lines ic in
      let token_ls =
        lines
        |> List.filter (fun line -> line != "" && String.get line 0 != '#')
        |> List.map (fun line -> Str.bounded_split (Str.regexp "=") line 2)
      in
      let () =
        token_ls
        |> List.filter (fun tokens -> List.length tokens > 1)
        |> List.iter (fun tokens ->
               match tokens with
               | key :: value :: _ -> add_new_tokens_to_env key value
               | _ -> ())
      in
      Lwt.return_unit
