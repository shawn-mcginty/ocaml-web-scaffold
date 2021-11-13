open Graphql_lwt.Schema

let user_typ : (Dream.request, User.t option) typ =
  obj "user" ~fields:(fun _info ->
      [
        field "id" ~typ:(non_null int)
          ~args:Arg.[]
          ~resolve:(fun _info user -> User.id user);
        field "first_name" ~typ:(non_null string)
          ~args:Arg.[]
          ~resolve:(fun _info user -> User.first_name user);
        io_field "items"
          ~typ:(non_null (list (non_null Item_schema.item_typ)))
          ~args:Arg.[]
          ~resolve:(fun info user ->
            let%lwt item_res =
              User.items user
              |> Lwt_list.map_p (fun item_id ->
                     Item_model.dataloader#load info.ctx item_id)
            in
            let res =
              List.fold_left
                (fun (final_res : (Item.t list, string) result)
                     (current_res : (Item.t, exn) result) ->
                  match (final_res, current_res) with
                  | Error _exn, _ -> Error "Could not load user items"
                  | _, Error _exn -> Error "Could not load user items"
                  | Ok items, Ok item -> Ok (item :: items))
                (Ok []) item_res
            in
            Lwt.return res);
      ])

let users_field : (Dream.request, unit) field =
  io_field "users"
    ~typ:(non_null (list (non_null user_typ)))
    ~args:Arg.[ arg "id" ~typ:int ]
    ~resolve:(fun info () id ->
      match id with
      | None ->
          let%lwt users = Dream.sql info.ctx User_model.list_users in
          Lwt.return (Ok users)
      | Some query_id ->
          let%lwt users = Dream.sql info.ctx (User_model.find_by_id query_id) in
          Lwt.return (Ok users))
