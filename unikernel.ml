open Lwt.Infix

(** HTTP server module type *)
module type HTTP = Cohttp_lwt.S.Server

(* Logging*)
let http_src = Logs.Src.create "http" ~doc:"HTTP server"
module Http_log = (val Logs.src_log http_src : Logs.LOG)


module Dispatch
         (FS : Mirage_types_lwt.KV_RO)
         (S  : HTTP) = struct

  (* Failure message formatter *)
  let failf fmt = Fmt.kstrf Lwt.fail_with fmt

  (* Whole file reader *)
  let read_whole_file fs name =
    FS.size fs name >>= function
    | Error e -> failf "size: %a" FS.pp_error e
    | Ok size ->
       FS.read fs name 0L size >>= function
       | Error e -> failf "read: %a" FS.pp_error e
       | Ok bufs -> Cstruct.copyv bufs |> Lwt.return

  (* URI -> response maker *)
  let rec dispatcher fs uri =
    match Uri.path uri with
    | "" | "/" -> Uri.with_path uri "index.html" |> dispatcher fs
    | path ->
       let mimetype = Magic_mime.lookup path in
       let headers = Cohttp.Header.init_with "content-type" mimetype in
       Lwt.catch
         (fun () ->
           read_whole_file fs path >>= fun body ->
           S.respond_string ~status:`OK ~body ~headers ())
         (fun _exn -> S.respond_not_found ())

  (* HTTP responder launch *)
  let serve dispatch =
    let callback (_, cid) request _body =
      let uri = Cohttp.Request.uri request in
      let cid = Cohttp.Connection.to_string cid in
      Http_log.info (fun f -> f "[%s] serving %s" cid (Uri.to_string uri));
      dispatch uri
    in
    let conn_closed (_, cid) =
      let cid = Cohttp.Connection.to_string cid in
      Http_log.info (fun f -> f "[%s] closing" cid)
    in
    S.make ~conn_closed ~callback ()
end

module CUSTOM_HTTP
         (Pclock : Mirage_types.PCLOCK)
         (DATA   : Mirage_types_lwt.KV_RO)
         (Http   : HTTP) = struct

  module D = Dispatch (DATA) (Http)

  let start _clock data http =
    let http_port = Key_gen.http_port () in
    let tcp = `TCP http_port in
    let http =
      Http_log.info (fun f -> f "listening on %d/TCP" http_port);
      http tcp @@ D.serve (D.dispatcher data)
    in
    http
end
