#!/bin/sh

if [[ -z "$1" || -z "$2" ]]; then
  echo "Usage: $0 <input-file|-> <output-file|->"
  exit 1
fi

sox "$1" -t raw -r 8000 -c 1 -e signed-integer "$2"

