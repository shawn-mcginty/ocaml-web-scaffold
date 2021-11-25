let enable_cors next req =
  let headers =
    [
      ("Access-Control-Allow-Origin", "*");
      ("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE");
      ( "Access-Control-Allow-Headers",
        "Host, Connection, Pragma, Cache-Control, User-Agent, Accept, Sec-GPC, \
         Origin, Sec-Fetch-Site, Sec-Fetch-Mode, Sec-Fetch-Dest, Referer, \
         Accept-Language, Content-Type, Content-Length, Accept-Encoding, \
         X-CSRF-Token, Authorization" );
    ]
  in
  match Dream.method_ req with
  | `OPTIONS -> Dream.respond ~status:`No_Content ~headers ""
  | _ ->
      let%lwt res = next req in
      let res_w_headers =
        res
        |> Dream.add_header "Access-Control-Allow-Origin" "*"
        |> Dream.add_header "Access-Control-Allow-Methods"
             "POST, GET, OPTIONS, PUT, DELETE"
        |> Dream.add_header "Access-Control-Allow-Headers"
             "Host, Connection, Pragma, Cache-Control, User-Agent, Accept, \
              Sec-GPC, Origin, Sec-Fetch-Site, Sec-Fetch-Mode, Sec-Fetch-Dest, \
              Referer, Accept-Language, Content-Type, Content-Length, \
              Accept-Encoding, X-CSRF-Token, Authorization"
      in
      Lwt.return res_w_headers

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
  Dream.serve @@ Dream.logger
  @@ Dream.sql_pool ~size:db_pool_size (Db_config.connection_string ())
  @@ enable_cors
  @@ Dream.router
       [
         Dream.any "/api/v1/graphql" (Dream.graphql Lwt.return Schemas.all);
         Dream.get "/api/v1/graphiql" (Dream.graphiql "/api/v1/graphql");
         Dream.get "/ping" (fun _ -> Dream.json "{\"status\":\"OK\"}");
       ]
  @@ Dream.not_found
