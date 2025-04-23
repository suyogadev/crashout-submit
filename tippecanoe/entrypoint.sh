#!/usr/bin/env bash

TILE_DIR="/data/tiles"
TILE_PATH="$TILE_DIR/crashes.pmtiles"
GEOJSON_PATH="/data/geojson/crashes.json"

LAYER_NAME="crashes"
TIPPECANOE_PATH="/usr/local/bin/tippecanoe"

# add a reset function
# cache needs to be manually cleared for a full reset
# unfortunately this also resets tilemaker, but i might figure out a better way to do this later
if [ "$1" == "reset" ]; then
    echo "[tippecanoe] resetting"
    rm -rfv "$TILE_DIR/"*
    exit $?
fi

[ -f "$TILE_PATH" ] && echo "[tippecanoe] traffic tiles already exist" && exit 0
[ ! -f "$GEOJSON_PATH" ] && echo "[tippecanoe] couldn't make traffic tiles, no geojson file found" && exit 1

echo "[tippecanoe] making traffic tiles"
"$TIPPECANOE_PATH" -zg -l "$LAYER_NAME" -o "$TILE_PATH" --drop-densest-as-needed "$GEOJSON_PATH" &&
    echo "[tippecanoe] traffic tiles created" && exit 0

echo "[tippecanoe] failed to make tiles" && exit 1
