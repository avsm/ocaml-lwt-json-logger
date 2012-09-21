#!/bin/sh

ocaml-crunch -e css -e js -e html -e png -m lwt -o lib/lwt_json_logger_files.ml lib_test
