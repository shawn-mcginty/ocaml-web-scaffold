module type DB = Caqti_lwt.CONNECTION

module Dynparam = Db_queries.Dynparam
module R = Caqti_request
module T = Caqti_type

let list_items =
  let query =
    R.collect T.unit T.(tup2 int string) "SELECT id, label FROM items"
  in
  fun (module Db : DB) ->
    let%lwt items_or_err = Db.collect_list query () in
    let%lwt itemTuples = Caqti_lwt.or_fail items_or_err in
    itemTuples |> List.map (fun (id, label) -> Item.make id label) |> Lwt.return

let list_by_ids (ids : int list) =
  let placeholders = List.map (fun _ -> "?") ids |> String.concat "," in
  let (Dynparam.Pack (typ, values)) =
    List.fold_left
      (fun pack id -> Dynparam.add Caqti_type.int id pack)
      Dynparam.empty ids
  in
  let sql =
    Printf.sprintf "SELECT id, label FROM items WHERE id in(%s)" placeholders
  in
  let query = R.collect typ T.(tup2 int string) sql in
  fun (module Db : DB) ->
    match ids with
    | [] -> Lwt.return []
    | _ ->
        let%lwt items_or_err = Db.collect_list query values in
        let%lwt itemTuples = Caqti_lwt.or_fail items_or_err in
        itemTuples
        |> List.map (fun (id, label) -> Item.make id label)
        |> Lwt.return

let find_by_id id =
  let query =
    R.collect T.int
      T.(tup2 int string)
      "SELECT id, label FROM items WHERE id = $1"
  in
  fun (module Db : DB) ->
    let%lwt items_or_err = Db.collect_list query id in
    let%lwt itemTuples = Caqti_lwt.or_fail items_or_err in
    itemTuples |> List.map (fun (id, label) -> Item.make id label) |> Lwt.return

let items_loader_fn (req : Dream.request) (item_ids : int list) :
    (Item.t list, exn) result Lwt.t =
  let%lwt items = Dream.sql req (list_by_ids item_ids) in
  List.map (fun id -> List.find (fun item -> Item.id item = id) items) item_ids
  |> Result.ok |> Lwt.return

let dataloader = new Dream_loader.dataloader items_loader_fn
