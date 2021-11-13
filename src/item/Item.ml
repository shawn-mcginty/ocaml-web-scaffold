type t = { id : int; label : string }

let make id label = { id; label }

let id item = item.id

let label item = item.label
