#!/usr/bin/env bash

# when using these functions, make sure utils.sh is sourced first!

parse_bounds() {
    # helper function for parsing the bounds csv to a geojson string
    #
    # usage: parse_bounds relative/path/to/bounds_file.csv output_dir/ bounds_file.json
    # returns 0 if file was parsed and successfully saved, 1 otherwise

    local BOUNDS_CSV="$1" OUTPUTDIR="$2" FILENAME="$3"
    local FILEPATH="$OUTPUTDIR/$FILENAME"

    message '[parse_bounds]' "attempting to parse bounds csv into geojson"

    local PARSED_BOUNDS=$(
        # get data from bounds csv
        cat "$HERE/$BOUNDS_CSV" |
        # select the geojson string
        tail -n +2 |
        cut -d '"' -f 2 |
        # parse the coordinates into a json array
        sed 's/, /,/g' |
        sed -r 's/([-.0-9][-.0-9]*) ([-.0-9][-.0-9]*)/\(\1,\2\)/g' |
        tr '()' '[]' |
        # wrap the coordinate data in a geojson object
        sed '
            s/MULTIPOLYGON /{"Name":"","RegionType":"geojson","RegionData":{"type":"MultiPolygon","coordinates":/
            s/$/}}/
        ' |
        # delete a problematic region; kind of a hacky fix but it's necessary
        jq -Mc 'del(.RegionData.coordinates[5][1])'
    )

    if [ $? -ne 0 ]; then
        message '[parse_bounds]' "parsing failure"
        return 1
    fi

    [ ! -d "$HERE/$OUTPUTDIR" ] && message '[parse_bounds]' "creating directory: '$OUTPUTDIR'"
    mkdir -p "$HERE/$OUTPUTDIR"

    if echo "$PARSED_BOUNDS" > "$HERE/$FILEPATH"; then
        message '[parse_bounds]' "geojson successfully saved: '$FILEPATH'"
        return 0
    fi

    message '[parse_bounds]' "failed to save parsed geojson"
    return 1
}

get_bounds() {
    # function for downloading gainesville map boundaries
    # produces the raw bounds csv and the parsed bounds geojson
    #
    # usage: get_bounds https://download.link output_dir/ bounds_file.csv bounds_file.json

    local URL="$1" OUTPUTDIR="$2" CSV_FILENAME="$3" JSON_FILENAME="$4"
    local CSV_FILEPATH="$OUTPUTDIR/$CSV_FILENAME" JSON_FILEPATH="$OUTPUTDIR/$JSON_FILENAME"

    message '[get_bounds]' "attempting to get map boundaries"

    if check_exists "$OUTPUTDIR" "$JSON_FILENAME"; then
        message '[get_bounds]' "parsed map boundaries found, success"
        return 0
    fi

    if ! check_exists "$OUTPUTDIR" "$CSV_FILENAME" &&
            ! download_url "$URL" "$OUTPUTDIR" "$CSV_FILENAME"; then
        message '[get_bounds]' "boundary download failed"
        return 1
    fi

    if parse_bounds "$OUTPUTDIR/$CSV_FILENAME" "$OUTPUTDIR" "$JSON_FILENAME"; then
        message '[get_bounds]' "bounds file parsed, success"
        return 0
    fi

    message '[get_bounds]' "failed to parse bounds file"
    return 1
}

download_mapid() {
    # helper function for fetching a map id from openstreetmap's slicing service
    # needs a path to the gainesville boundary json and the slicing service url
    #
    # usage: download_mapid relative/path/to/bounds_file.json https://slice.osm.url output_dir/ mapid.txt
    # returns 0 if the download succeeded and 1 if it didn't

    local BOUNDS_JSON="$1" OSM_URL="$2" OUTPUTDIR="$3" FILENAME="$4"
    local FILEPATH="$OUTPUTDIR/$FILENAME"

    message '[download_mapid]' "reading geojson: '$BOUNDS_JSON'"

    local PARSED_BOUNDS=$(cat "$HERE/$BOUNDS_JSON")

    local OSM_ENDPOINT="$OSM_URL/api/"

    message '[download_mapid]' "fetching (using geojson as body): '$OSM_ENDPOINT'"

    [ ! -d "$HERE/$OUTPUTDIR" ] && message '[download_mapid]' "creating directory: '$OUTPUTDIR'"
    mkdir -p "$HERE/$OUTPUTDIR"

    curl -s -f -o "$HERE/$FILEPATH" -X POST "$OSM_ENDPOINT" -d "$PARSED_BOUNDS"
    local DL_STATUS=$?

    if [ $DL_STATUS -eq 0 ]; then
        message '[download_mapid]' "successfully got map id: '$FILEPATH'"
        return 0
    fi

    message '[download_mapid]' "download failed with status $DL_STATUS"
    return 1
}

download_map() {
    # helper function for downloading a map from openstreetmap's slicing service
    # needs a path to a file containing the map id and the slicing service url
    #
    # usage: download_map relative/path/to/mapid.txt https://slice.osm.url output_dir/ response_file.json map_file.osm.pbf

    local MAPID="$1" OSM_URL="$2" OUTPUTDIR="$3" RESPONSE_FILENAME="$4" MAP_FILENAME="$5"
    local RESPONSE_FILEPATH="$OUTPUTDIR/$RESPONSE_FILENAME" MAP_FILEPATH="$OUTPUTDIR/$MAP_FILENAME"

    message '[download_map]' "reading map id: '$MAPID'"

    local WRAP=40
    local PARSED_MAPID=$(cat "$HERE/$MAPID")
    if [ ${#PARSED_MAPID} -gt $WRAP ]; then
        message '[download_map]' "map id too long, truncating to 40 chars"
        PARSED_MAPID="${PARSED_MAPID:0:$WRAP}"
    fi

    local OSM_ENDPOINT="$OSM_URL/api/$PARSED_MAPID"

    local RETRY_COUNT=3
    local RETRY_DELAY=10

    message '[download_map]' "checking status of map id"

    for i in $(seq 1 $RETRY_COUNT); do
        if download_url "$OSM_ENDPOINT" "$OUTPUTDIR" "$RESPONSE_FILENAME"; then
            if cat "$HERE/$RESPONSE_FILEPATH" | jq -e '.Complete == true' > /dev/null; then
                message '[download_map]' "map download ready"

                message '[download_map]' "deleting response, no longer needed"
                rm "$HERE/$RESPONSE_FILEPATH"

                break
            fi

            message '[download_map]' "status indicates map not ready"
        else
            message '[download_map]' "status check failed"
        fi

        if [ $i -ne $RETRY_COUNT ]; then
            message '[download_map]' "retrying in $RETRY_DELAY seconds"
            sleep $RETRY_DELAY
        else
            message '[download_map]' "maximum retry count of $RETRY_COUNT reached"

            message '[download_map]' "failed to download map, check '$RESPONSE_FILENAME'"
            return 1
        fi
    done

    OSM_ENDPOINT="$OSM_URL/files/${PARSED_MAPID}.osm.pbf"

    if download_url "$OSM_ENDPOINT" "$OUTPUTDIR" "$MAP_FILENAME"; then
        message '[download_map]' "map downloaded, success"
        return 0
    fi

    message '[download_map]' "map download failed"
    return 1
}
