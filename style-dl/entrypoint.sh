#!/usr/bin/env sh

DATA_DIR="/data"
STYLE_DIR="$DATA_DIR/style"
FONT_DIR="$DATA_DIR/fonts"

CACHE_DIR="/cache"
STYLEZIP_NAME="style.zip"
FONTZIP_NAME="fonts.zip"

PATCH_DIR="/patches"
SCRIPTS_DIR="/scripts"

# add a reset function
# cache needs to be manually cleared for a full reset
if [ "$1" == "reset" ]; then
    echo "[style-dl] resetting"
    rm -rfv "$DATA_DIR/"*
    exit $?
fi

if [ ! -d "$STYLE_DIR" ] || [ ! -d "$FONT_DIR" ]; then
    apk add jq curl bash

    "$SCRIPTS_DIR/get-all.sh" "$DATA_DIR" "$STYLE_DIR" "$FONT_DIR" "$CACHE_DIR" \
        "$STYLEZIP_NAME" "$FONTZIP_NAME" "$PATCH_DIR" "$SCRIPTS_DIR"
else
    echo "[style-dl] style data directories already exist"
fi
