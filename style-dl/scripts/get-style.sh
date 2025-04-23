#!/usr/bin/env bash

#
# script for downloading the style for the map
#

OUTPUTDIR="$1"
CACHEDIR="$2"
FILENAME="$3"

PATCHDIR="$4"
PATCHGLOB="*.jq"

STYLE="style-local.json"
NEWSTYLE="style.json"
GLOB="style-*.json"

URL="https://github.com/openmaptiles/osm-bright-gl-style/releases/download/v1.11/v1.11.zip"

HERE="$5"

# import helper functions
source "$HERE/utils.sh"
source "$HERE/utils-style.sh"

HERE=/  # absolute path fix for docker

get_style() {
    # function to get the rest of the style data (aka everything but fonts)
    # there are way too many parameters so i will not be writing a usage guide

    local OUTPUTDIR="$1" CACHEDIR="$2" FILENAME="$3"
    local PATCHDIR="$4" PATCHGLOB="$5"
    local STYLE="$6" NEWSTYLE="$7" GLOB="$8"
    local URL="$9"

    message '[get_style]' "attempting to get style"

    if check_exists_dir "$OUTPUTDIR"; then
        message '[get_style]' "style directory found, success"
        return 0
    fi

    message '[get_style]' "looking for style zip"

    if ! check_exists "$CACHEDIR" "$FILENAME" && ! download_url "$URL" "$CACHEDIR" "$FILENAME"; then
        message '[get_style]' "download failed, cannot continue"
        return 1
    fi

    message '[get_style]' "extracting: '$OUTPUTDIR'"

    if ! extract_file "$CACHEDIR/$FILENAME" "$OUTPUTDIR"; then
        message '[get_style]' "extraction failed"
        return 1
    fi

    message '[get_style]' "cleaning the style directory"

    if ! clean_style "$OUTPUTDIR" "$PATCHDIR" "$PATCHGLOB" "$STYLE" "$NEWSTYLE" "$GLOB"; then
        message '[get_style]' "cleanup failed, cannot continue"

        rm -rf "$OUTPUTDIR" && message '[get_style]' "removed style directory"
        return 1
    fi

    message '[get_style]' "all files successfully extracted"
    return 0
}

get_style "$OUTPUTDIR" "$CACHEDIR" "$FILENAME" "$PATCHDIR" \
    "$PATCHGLOB" "$STYLE" "$NEWSTYLE" "$GLOB" "$URL"
