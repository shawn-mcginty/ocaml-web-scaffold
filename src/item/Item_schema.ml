open Graphql_lwt.Schema

let item_typ : (Dream.request, Item.t option) typ =
  obj "item" ~fields:(fun _info ->
      [
        field "id" ~typ:(non_null int)
          ~args:Arg.[]
          ~resolve:(fun _info item -> Item.id item);
        field "label" ~typ:(non_null string)
          ~args:Arg.[]
          ~resolve:(fun _info item -> Item.label item);
      ])

let item_field : (Dream.request, unit) field =
  io_field "items"
    ~typ:(non_null (list (non_null item_typ)))
    ~args:Arg.[ arg "id" ~typ:int ]
    ~resolve:(fun info () id ->
      match id with
      | None ->
          let%lwt items = Dream.sql info.ctx Item_model.list_items in
          Lwt.return (Ok items)
      | Some query_id ->
          let%lwt items = Dream.sql info.ctx (Item_model.find_by_id query_id) in
          Lwt.return (Ok items))
