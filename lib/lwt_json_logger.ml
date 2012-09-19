(*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Lwt
open Printf

(* This will be parsed by the Javascript to render the log levels *)
let json_of_level =
  let open Lwt_log in function
  |Debug -> "default"
  |Info -> "info"
  |Notice -> "notice"
  |Warning -> "warning"
  |Error -> "error"
  |Fatal -> "fatal"

(* Construct a Lwt_json_log instance.
 * @param droot Document root of the web pages.
 * @param port TCP port to listen for HTTP requests on.
 * @param address IP address to bind to (default: 127.0.0.1)
 *)
let make ?(address="127.0.0.1") ~droot ~port () =
  (* Buffer up the log messages until the client polls again.
   * TODO There is currently no limit on the size of this buffer. 
   *)
  let log_buffer = ref [] in

  (* Output a list of lines at a particular section and level. *)
  let output section level lines =
    (* As a hack, any sections marked "progress_*" will result in a progress
     * bar being logged, and a callback thread to update it.
     *)
    try begin
      let progress_id = Scanf.sscanf (Lwt_log.Section.name section) "progress_%s" (fun id -> id) in
      (* If this is a progress section, then we have a single line with the progress percentage *)
      match lines with 
      |[p] ->
         let json =
           `Assoc [
             "mode", `String "progress";
             "id", `String progress_id;
             "level", `String (json_of_level level);
             "width", `String p;
             "date", `String (sprintf "%f" (Unix.gettimeofday () *. 1000.))
         ] in
         log_buffer := json :: !log_buffer;
         return ()
      |_ -> failwith ""
    end with exn -> begin
      (* If it is not a progress bar, just render it normally *)
      let json =
        `Assoc [
          "mode", `String "log";
          "level", `String (json_of_level level); 
          "data", `List (List.map (fun x -> `String x) lines);
          "date", `String (sprintf "%f" (Unix.gettimeofday () *. 1000.))
        ]
      in
      log_buffer := json :: !log_buffer;
      return ()
    end
  in
  (* Callback function to pass to Cohttpd *)
  let callback id ?body req =
    let module C = Cohttp in
    let module CLS = Cohttp_lwt_unix.Server in
    let module CLR = Cohttp_lwt_unix.Request in
    (* Retrieve the latest log buffer and return it as JSON array *)
    let poll_log_buffer () =
      let json = `List (List.rev !log_buffer) in
      log_buffer := [];
      let body = Yojson.Basic.to_string ~std:true json in
      CLS.respond_string ~status:`OK ~body ()
    in
    (* Just assume we control the whole HTTP server for now, which we do.
     * The Bootstrap files need to be in ~droot.
     * XXX TODO: close the horrible security hole with path traversal
     * as ocaml-uri needs a normalize path function, see ocaml-uri issue #3
     *)
    Printf.printf "%s %s\n%!" (C.Code.string_of_method (CLR.meth req)) (CLR.path req);
    match CLR.meth req, CLR.path req with
    |`GET, "/log.json" -> poll_log_buffer ()
    |`GET,"/" -> CLS.respond_file ~docroot:droot ~fname:"index.html" ()
    |`GET,path -> CLS.respond_file ~docroot:droot ~fname:path ()
    |_ -> CLS.respond_not_found ()
  in
  (* Cohttpd server thread *)
  let server_t = 
    let conn_closed _ _ = () in
    let config = { Cohttp_lwt_unix.Server.callback; conn_closed } in
    Cohttp_lwt_unix.server "0.0.0.0" 8080 config
  in
  (* Logger close function will shut down the server_t http thread *)
  let close logger =
    Printf.printf "shutting down logger cohttp server\n%!";
    Lwt.cancel server_t;
    return ()
  in
  Lwt_log.make ~output ~close

(* Log a progress message *)
let progress ~task ~stream ~logger ~level =
  (* Create a section with this id *)
  let section = Lwt_log.Section.make ("progress_"^task) in
  Lwt_stream.iter_s ( fun progress ->
    let progress = if progress < 0. then 0. else (if progress > 100. then 100. else progress) in
    Lwt_log.log ~section ~level ~logger (string_of_int (int_of_float progress))
  ) stream

