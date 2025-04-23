#!/usr/bin/env sh

DATA_DIR="/data"
CRASH_FILENAME="crashes.csv"
MAP_FILENAME="gnv.osm.pbf"

CACHE_DIR="/cache"

SCRIPTS_DIR="/scripts"

# add a reset function
# cache needs to be manually cleared for a full reset
if [ "$1" == "reset" ]; then
    echo "[data-dl] resetting"
    rm -rfv "$DATA_DIR/"*
    exit $?
fi

if [ ! -f "$DATA_DIR/$CRASH_FILENAME" ] || [ ! -f "$DATA_DIR/$MAP_FILENAME" ]; then
    apk add jq curl bash

    "$SCRIPTS_DIR/get-all.sh" "$DATA_DIR" "$CRASH_FILENAME" "$MAP_FILENAME" "$CACHE_DIR" "$SCRIPTS_DIR"
else
    echo "[data-dl] raw data already downloaded"
fi
