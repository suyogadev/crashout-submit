#!/usr/bin/env bash

#
# script file for downloading the map data for gainesville, filtered by its boundaries
#

# args are now passed in from entrypoint
OUTPUTDIR="$1"
FILENAME="$2"

CACHEDIR="$3"
MAPID_FILENAME="mapid.txt"
BOUNDS_CSV_FILENAME="bounds.csv"
BOUNDS_JSON_FILENAME="bounds.json"
RESPONSE_FILENAME="response.json"

OSM_URL="https://slice.openstreetmap.us"  # DO NOT INCLUDE trailing / or /api or /data, the script handles that
BOUNDS_URL="https://data.cityofgainesville.org/api/views/wubr-vuft/rows.csv?accessType=DOWNLOAD"

HERE="$4"

# import helper functions
source "$HERE/utils.sh"
source "$HERE/utils-map.sh"

HERE=/  # absolute path fix for docker

get_map() {
    # function to get gainesville map data
    # there are way too many parameters so i will not be writing a usage guide

    local OUTPUTDIR="$1" FILENAME="$2"
    local CACHEDIR="$3" MAPID_FILENAME="$4" BOUNDS_CSV_FILENAME="$5" BOUNDS_JSON_FILENAME="$6" RESPONSE_FILENAME="$7"
    local OSM_URL="$8" BOUNDS_URL="$9"

    message '[get_map]' "attempting to get gainesville map"

    if check_exists "$OUTPUTDIR" "$FILENAME"; then
        message '[get_map]' "map found, success"
        return 0
    fi

    message '[get_map]' "starting map download"

    if check_exists "$CACHEDIR" "$MAPID_FILENAME" &&
            download_map "$CACHEDIR/$MAPID_FILENAME" "$OSM_URL" "$OUTPUTDIR" "$RESPONSE_FILENAME" "$FILENAME"; then
        message '[get_map]' "map downloaded from cached map id, success"
        return 0
    fi

    if ! get_bounds "$BOUNDS_URL" "$CACHEDIR" "$BOUNDS_CSV_FILENAME" "$BOUNDS_JSON_FILENAME"; then
        message '[get_map]' "failed to download boundaries, cannot continue"
        return 1
    fi

    if ! download_mapid "$CACHEDIR/$BOUNDS_JSON_FILENAME" "$OSM_URL" "$CACHEDIR" "$MAPID_FILENAME"; then
        message '[get_map]' "failed to fetch map id, cannot continue"
        return 1
    fi

    if ! download_map "$CACHEDIR/$MAPID_FILENAME" "$OSM_URL" "$OUTPUTDIR" "$RESPONSE_FILENAME" "$FILENAME"; then
        message '[get_map]' "map download failed"
        return 1
    fi

    message '[get_map]' "successfully fetched map"
    return 0
}

get_map "$OUTPUTDIR" "$FILENAME" "$CACHEDIR" "$MAPID_FILENAME" \
    "$BOUNDS_CSV_FILENAME" "$BOUNDS_JSON_FILENAME" "$RESPONSE_FILENAME" \
    "$OSM_URL" "$BOUNDS_URL"
