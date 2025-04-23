#!/usr/bin/env bash

DATA_DIR="$1"
CRASH_FILENAME="$2"
MAP_FILENAME="$3"

CACHE_DIR="$4"

HERE="$5"

"$HERE/get-crashes.sh" "$DATA_DIR" "$CRASH_FILENAME" "$HERE" &&
    "$HERE/get-map.sh" "$DATA_DIR" "$MAP_FILENAME" "$CACHE_DIR" "$HERE"
