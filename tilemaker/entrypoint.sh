#!/usr/bin/env bash

TILE_DIR="/data/tiles"
TILE_PATH="$TILE_DIR/gnv.pmtiles"
PBF_PATH="/data/raw/gnv.osm.pbf"

TILEMAKER_PATH="/usr/src/app/tilemaker"

# add a reset function
# cache needs to be manually cleared for a full reset
# unfortunately this also resets tippecanoe, but i might figure out a better way to do this later
if [ "$1" == "reset" ]; then
    echo "[tilemaker] resetting"
    rm -rfv "$TILE_DIR/"*
    exit $?
fi

[ -f "$TILE_PATH" ] && echo "[tilemaker] tiles already exist" && exit 0
[ ! -f "$PBF_PATH" ] && echo "[tilemaker] couldn't make tiles, no PBF file found" && exit 1

echo "[tilemaker] making tiles"
"$TILEMAKER_PATH" --input "$PBF_PATH" --output "$TILE_PATH" && echo "[tilemaker] tiles created" && exit 0

echo "[tilemaker] failed to make tiles" && exit 1
