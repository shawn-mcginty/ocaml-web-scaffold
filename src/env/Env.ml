exception Env_exception of string

let get_required key_str =
  match Sys.getenv_opt key_str with
  | Some v -> v
  | None ->
      raise
        (Env_exception
           (Printf.sprintf "Environment variable %s is required." key_str))

let get_opt key_str = Sys.getenv_opt key_str
