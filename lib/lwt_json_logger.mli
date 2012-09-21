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

val make : ?address:string -> port:int -> unit -> Lwt_log.logger
(** 
  Make a JSON logger and HTTP server to serve up the pages.
  @param address The IP address to listen on (default 127.0.0.1)
  @param port HTTP TCP port to listen on
 *)

val progress :
  task:string ->
  stream:float Lwt_stream.t ->
  logger:Lwt_log.logger -> level:Lwt_log.level -> unit Lwt.t
(**
  Log a progress bar to the HTTP interface. Takes a [task] to identify
  the specific bar, and an Lwt_stream to push the client pushes width
  updates (where the width is a percentage (from 0-100).
  This actually leaks a bit of memory for each progress bar at present,
  since it uses a fake Lwt_log.Section level to mark the update as a 
  progress bar. Requires per-log metadata to anything better I think.
 *)
