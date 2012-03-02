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

(* Generate JSON log messages *)
let logger = Lwt_json_logger.make ~droot:"lib_test/" ~port:8080 ()

let log_t = 
  while_lwt true do
    Lwt_log.notice ~logger "foo!" >>
    Lwt_unix.sleep 2. >>
    Lwt_log.info ~logger "bar!" >>
    Lwt_unix.sleep 1. >>
    Lwt_log.error ~logger "eeeek!" >>
    Lwt_unix.sleep 2.
  done

let _ =
  Lwt_main.run log_t

