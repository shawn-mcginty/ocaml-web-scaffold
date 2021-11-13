module type DB = Caqti_lwt.CONNECTION

module R = Caqti_request
module T = Caqti_type
module Int_map = Map.Make (Int)

let user_sql =
  "SELECT u.id, u.first_name, ui.item_id FROM users u LEFT OUTER JOIN \
   user_items ui ON u.id = ui.user_id"

let user_fields = T.(tup3 int string (option int))

let fold_users (id, first_name, item_id) (users_map : User.t Int_map.t) =
  Int_map.update id
    (fun existing_u ->
      match (existing_u, item_id) with
      | None, None -> Some (User.make id first_name)
      | None, Some i_id -> Some (User.make ~items:[ i_id ] id first_name)
      | Some u, None -> Some u
      | Some u, Some i_id ->
          let new_items = i_id :: User.items u in
          Some (User.make ~items:new_items id first_name))
    users_map

let user_map_to_list _ u users = u :: users

let users_from_query users_or_err =
  let%lwt usersMap = Caqti_lwt.or_fail users_or_err in
  Int_map.fold user_map_to_list usersMap [] |> Lwt.return

let list_users =
  let query = R.collect T.unit user_fields user_sql in
  fun (module Db : DB) ->
    let%lwt users_or_err = Db.fold query fold_users () Int_map.empty in
    users_from_query users_or_err

let find_by_id id =
  let query = R.collect T.int user_fields (user_sql ^ " WHERE id = $1") in
  fun (module Db : DB) ->
    let%lwt users_or_err = Db.fold query fold_users id Int_map.empty in
    users_from_query users_or_err
