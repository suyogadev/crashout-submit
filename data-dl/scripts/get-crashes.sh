#!/usr/bin/env bash

#
# script file for downloading gainesville's traffic crash data
#

# args are now passed in from entrypoint
OUTPUTDIR="$1"
FILENAME="$2"

URL="https://data.cityofgainesville.org/api/views/iecn-3sxx/rows.csv?accessType=DOWNLOAD"

HERE="$3"

# import helper functions
source "$HERE/utils.sh"

HERE=/  # absolute path fix for docker

get_crashes() {
    # function to get gainesville crash data
    # considered successful if the data already exists
    #
    # usage: https://download.link output_dir/ output_name
    # returns 0 if the data was retrieved and 1 otherwise

    local URL="$1" OUTPUTDIR="$2" FILENAME="$3"

    message '[get_crashes]' "attempting to get crash data"

    if check_exists "$OUTPUTDIR" "$FILENAME"; then
        message '[get_crashes]' "crash data found, success"
        return 0
    fi

    if download_url "$URL" "$OUTPUTDIR" "$FILENAME"; then
        message '[get_crashes]' "crash data downloaded, success"
        return 0
    fi

    message '[get_crashes]' "failed to get crash data"
    return 1
}

get_crashes "$URL" "$OUTPUTDIR" "$FILENAME"
