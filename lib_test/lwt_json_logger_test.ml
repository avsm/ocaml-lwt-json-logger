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
  let normal_t =
    while_lwt true do
      Lwt_log.notice ~logger "foo!" >>
      Lwt_unix.sleep 2. >>
      Lwt_log.info ~logger "bar!" >>
      Lwt_unix.sleep 1. >>
      Lwt_log.error ~logger "eeeek!" >>
      Lwt_unix.sleep 2.
    done
  in
  (* progress bar generator *)
  let progress_t id =
    (* create the section *)
    let section = Lwt_log.Section.make ("progress_" ^ id) in
    (* Initialise it to 0 *)
    Lwt_log.notice ~logger ~section "0" >>
    (* Progress up to 100 in random increments *)
    let progress = ref 0 in
    while_lwt !progress < 100 do
      progress := !progress + (Random.int 10);
      Lwt_unix.sleep (Random.float 1.) >>
      Lwt_log.notice ~logger ~section (string_of_int !progress)
    done
  in
  let _ = progress_t "foo" in
  let _ = Lwt_unix.sleep 3.0 >> progress_t "bar" in
  let _ = Lwt_unix.sleep 4.0 >> progress_t "char" in
  normal_t

let _ =
  Lwt_main.run log_t

