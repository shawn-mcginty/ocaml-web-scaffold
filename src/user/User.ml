type t = { id : int; first_name : string; items : int list }

let make ?items id first_name =
  match items with
  | Some i -> { id; first_name; items = i }
  | None -> { id; first_name; items = [] }

let id u = u.id

let first_name u = u.first_name

let items u = u.items