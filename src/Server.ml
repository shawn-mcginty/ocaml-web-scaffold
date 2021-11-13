let serve () =
  let default_db_pool_size = 10 in
  let db_pool_size =
    match Env.get_opt "DB_POOL_SIZE" with
    | None -> default_db_pool_size
    | Some size -> int_of_string size
  in
  let default_port = 8080 in
  let port =
    match Env.get_opt "PORT" with
    | None -> default_port
    | Some p -> int_of_string p
  in
  let () = Printf.sprintf "listening on port %i" port |> print_endline in
  Dream.serve @@ Dream.logger @@ Dream.origin_referer_check
  @@ Dream.sql_pool ~size:db_pool_size (Db_config.connection_string ())
  @@ Dream.router
       [
         Dream.any "/api/v1/graphql" (Dream.graphql Lwt.return Schemas.all);
         Dream.get "/api/v1/graphiql" (Dream.graphiql "/api/v1/graphql");
         Dream.get "/ping" (fun _ -> Dream.json "{\"status\":\"OK\"}");
       ]
  @@ Dream.not_found
