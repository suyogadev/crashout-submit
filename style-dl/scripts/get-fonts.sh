#!/usr/bin/env bash

#
# script for downloading the fonts for the map
#

OUTPUTDIR="$1"
CACHEDIR="$2"
FILENAME="$3"

URL="https://github.com/openmaptiles/fonts/releases/download/v2.0/noto-sans.zip"

HERE="$4"

# import helper functions
source "$HERE/utils.sh"

HERE=/  # absolute path fix for docker

get_fonts() {
    # function to get the fonts for the map style
    # considered sucessful if the font directory exists (contents not verified)
    #
    # usage: get_fonts path/to/fontdir path/to/cachedir path/to/fonts.zip https://link.to/fonts.zip

    local OUTPUTDIR="$1" CACHEDIR="$2" FILENAME="$3" URL="$4"

    message '[get_fonts]' "attempting to get fonts"

    if check_exists_dir "$OUTPUTDIR"; then
        message '[get_fonts]' "font directory found, success"
        return 0
    fi

    message '[get_fonts]' "looking for font zip"

    if ! check_exists "$CACHEDIR" "$FILENAME" && ! download_url "$URL" "$CACHEDIR" "$FILENAME"; then
        message '[get_fonts]' "download failed with status $?"
        return 1
    fi

    message '[get_fonts]' "extracting: '$OUTPUTDIR'"

    if ! extract_file "$CACHEDIR/$FILENAME" "$OUTPUTDIR"; then
        message '[get_fonts]' "extraction failed"
        return 1
    fi

    message '[get_fonts]' "all files successfully extracted"
    return 0
}

get_fonts "$OUTPUTDIR" "$CACHEDIR" "$FILENAME" "$URL"
