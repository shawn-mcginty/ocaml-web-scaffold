type ('key, 'value, 'err) batch = {
  has_dispatched : bool;
  keys : 'key list;
  promises : ('value, 'err) result Lwt.u list;
  req : Dream.request option;
}

type ('key, 'value, 'err) loader =
  Dream.request -> 'key list -> ('value list, 'err) result Lwt.t

exception Dataload_error of string

let empty_batch =
  { has_dispatched = false; keys = []; promises = []; req = None }

class ['key, 'value, 'err] dataloader (loader : ('key, 'value, 'err) loader) =
  object (self)
    val mutable batch : ('key, 'value, 'err) batch option = None

    val mutable is_scheduled = false

    method current_batch () =
      match batch with
      | None ->
          batch <- Some empty_batch;
          Option.value ~default:empty_batch batch
      | Some { has_dispatched = true; _ } ->
          batch <- Some empty_batch;
          Option.value ~default:empty_batch batch
      | Some b -> b

    method mark_dispatched has_it =
      let b = Option.value ~default:empty_batch batch in
      batch <- Some { b with has_dispatched = has_it }

    method push_batch_item (req : Dream.request) (key : 'key) p =
      let b = self#current_batch () in
      let updated_batch =
        {
          b with
          req = Some req;
          keys = key :: b.keys;
          promises = p :: b.promises;
        }
      in
      batch <- Some updated_batch

    (* TODO: Make this smarter, i.e. have some max and a timeout *)
    method schedule_now () =
      match is_scheduled with
      | true -> Lwt.return_unit
      | false -> (
          is_scheduled <- true;
          let%lwt () = Lwt_unix.sleep 0.01 in
          let b = self#current_batch () in
          let () = self#mark_dispatched true in
          is_scheduled <- false;
          let%lwt result =
            Lwt.catch
              (fun () ->
                match b.req with
                | Some req -> loader req b.keys
                | None ->
                    Lwt.fail
                      (Dataload_error "Dream request is required for dataloader"))
              (fun exn -> Lwt.return (Error exn))
          in
          match result with
          | Error exn ->
              List.iter (fun r -> Lwt.wakeup_later r (Error exn)) b.promises
              |> Lwt.return
          | Ok values -> (
              match List.length values = List.length b.promises with
              | false ->
                  raise
                    (Dataload_error
                       "Dataloader misconfigured. Number of values returned \
                        does not match number of keys to be loaded.")
              | true ->
                  List.iter2
                    (fun value promise -> Lwt.wakeup_later promise (Ok value))
                    values b.promises
                  |> Lwt.return))

    method load req key =
      let p, r = Lwt.wait () in
      let () = self#push_batch_item req key r in
      let _ = self#schedule_now () in
      p
  end
