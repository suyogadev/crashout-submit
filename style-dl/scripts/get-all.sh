#!/usr/bin/env bash

DATA_DIR="$1"
STYLE_DIR="$2"
FONT_DIR="$3"

CACHE_DIR="$4"
STYLEZIP_NAME="$5"
FONTZIP_NAME="$6"

PATCH_DIR="$7"

HERE="$8"

"$HERE/get-style.sh" "$STYLE_DIR" "$CACHE_DIR" "$STYLEZIP_NAME" "$PATCH_DIR" "$HERE" &&
    "$HERE/get-fonts.sh" "$FONT_DIR" "$CACHE_DIR" "$FONTZIP_NAME" "$HERE"
