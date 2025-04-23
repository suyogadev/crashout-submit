#!/usr/bin/env bash

message() {
    # helper function for printing debug messages in the unified format
    #
    # usage: message prefix the_message

    local PREFIX="$1" MESSAGE="$2"
    echo "$PREFIX" "$MESSAGE" | fold -w 76 -s | sed '2,$s/^/    /'
    return 0
}

check_exists() {
    # helper function for checking if a file exists, but with debug messages
    #
    # usage: check_exists parent_dir/ file_name
    # alternate usage: check_exists relative/path/to/file
    # returns 0 if the file exists and 1 if it doesn't

    if [ $# -eq 1 ]; then
        local FILEPATH="$1"
    else
        local OUTPUTDIR="$1" FILENAME="$2"
        local FILEPATH="$OUTPUTDIR/$FILENAME"
    fi

    message '[check_exists]' "checking file: '$FILEPATH'"

    if [ -f "$HERE/$FILEPATH" ]; then
        message '[check_exists]' "file exists"
        return 0
    fi

    message '[check_exists]' "file does not exist"
    return 1
}

check_exists_dir() {
    # helper function for checking if a directory exists, but with debug messages
    #
    # usage: check_exists the_dir/
    # returns 0 if the directory exists and 1 if it doesn't

    local FILEPATH="$1"

    message '[check_exists_dir]' "checking directory: '$FILEPATH'"

    if [ -d "$HERE/$FILEPATH" ]; then
        message '[check_exists_dir]' "directory exists"
        return 0
    fi

    message '[check_exists_dir]' "directory does not exist"
    return 1
}

download_url() {
    # helper function for downloading a file from a URL, but with debug messages
    #
    # usage: download_url https://the.url output_dir/ output_name
    # returns 0 if the download succeeded and 1 if it didn't

    local URL="$1" OUTPUTDIR="$2" FILENAME="$3"
    local FILEPATH="$OUTPUTDIR/$FILENAME"

    message '[download_url]' "fetching: '$URL'"

    [ ! -d "$HERE/$OUTPUTDIR" ] && message '[download_url]' "creating directory: '$OUTPUTDIR'"
    mkdir -p "$HERE/$OUTPUTDIR"

    curl -L -s -f -o "$HERE/$FILEPATH" "$URL"
    local DL_STATUS=$?

    if [ $DL_STATUS -eq 0 ]; then
        message '[download_url]' "successfully downloaded: '$FILEPATH'"
        return 0
    fi

    message '[download_url]' "download failed with status $DL_STATUS"
    return 1
}

extract_file() {
    # helper function for extracting a file, but with debug messages
    # deletes the directory if the extraction fails
    #
    # usage: extract_file /path/to/file.zip output_dir/
    # returns 0 if the extraction succeeded and 1 otherwise

    local FILEPATH="$1" OUTPUTDIR="$2"

    message '[extract_file]' "extracting: '$FILEPATH'"

    unzip "$HERE/$FILEPATH" -d "$HERE/$OUTPUTDIR"
    local ZIP_STATUS=$?

    if [ $ZIP_STATUS -eq 0 ]; then
        message '[extract_file]' "extraction success: '$OUTPUTDIR'"
        return 0
    fi

    message '[extract_file]' "extraction failed with status $ZIP_STATUS"

    rm -rf "$HERE/$OUTPUTDIR" && message '[extract_file]' "removed directory: '$OUTPUTDIR'"
    return 1
}
