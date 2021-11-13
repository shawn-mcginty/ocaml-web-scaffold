let connection_string () =
  Printf.sprintf "postgres://%s:%s@%s:%s/%s?sslmode=disable"
    (Env.get_required "DB_USER")
    (Env.get_required "DB_PASSWORD")
    (Env.get_required "DB_HOST")
    (Env.get_required "DB_PORT")
    (Env.get_required "DB_NAME")
