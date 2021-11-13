let main () =
  let () = print_endline "Reading environment..." in
  let%lwt () = Load_dotenv.load () in
  let () = print_endline "Fixing to start the server..." in
  Server.serve ()

let _ = Lwt_main.run @@ main ()