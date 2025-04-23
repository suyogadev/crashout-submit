#!/usr/bin/env bash

# when using these functions, make sure utils.sh is sourced first!

shopt -s nullglob  # prevent unexpected failures when expanding globs

UNWANTED_FILES=("index.html")

clean_style() {
    # helper function to patch the main style json
    #
    # usage: path/to/styledir path/to/patchdir path/to/fonts.zip chosen-style.json new-name.json other-styles-*.json
    # returns 0 if patching and renaming succeeds and 1 otherwise

    local OUTPUTDIR="$1" PATCHDIR="$2" PATCHGLOB="$3" STYLE="$4" FILENAME="$5" GLOB="$6"

    message '[clean_style]' "renaming main style: '$OUTPUTDIR/$STYLE'"

    if ! mv "$HERE/$OUTPUTDIR/$STYLE" "$HERE/$OUTPUTDIR/$FILENAME"; then
        message '[clean_style]' "rename failed"
        return 1
    fi

    message '[clean_style]' "renamed: '$OUTPUTDIR/$FILENAME'"

    message '[clean_style]' "removing other styles: '$OUTPUTDIR/$GLOB'"

    if ! rm -rf "$HERE/$OUTPUTDIR/"$GLOB; then
        message '[clean_style]' "deletion failed"
        return 1
    fi

    message '[clean_style]' "removing unwanted files"

    for REMOVEFILE in "${UNWANTED_FILES[@]}"; do
        rm "$HERE/$OUTPUTDIR/$REMOVEFILE" && message '[clean_style]' "removed file: '$OUTPUTDIR/$REMOVEFILE'"
    done

    message '[clean_style]' "patching: '$OUTPUTDIR/$FILENAME'"

    local LC_ALL=C
    for PATCHFILE in "$HERE/$PATCHDIR/"$PATCHGLOB; do
        message '[clean_style]' "applying patch: '$PATCHFILE'"

        local PATCH
        PATCH=$(jq -f "$HERE/$PATCHFILE" "$HERE/$OUTPUTDIR/$FILENAME")

        if [ $? -ne 0 ]; then
            message '[clean_style]' "patch application failed"

            mv "$HERE/$OUTPUTDIR/$FILENAME" "$HERE/$CACHEDIR/$FILENAME" &&
                message '[clean_style]' "moved style json to cache: '$CACHEDIR/$FILENAME'"
            return 1
        fi

        if ! echo "$PATCH" > "$HERE/$OUTPUTDIR/$FILENAME"; then
           message '[clean_style]' "failed to write patch"
           return 1
        fi
    done

    message '[clean_style]' "successfully applied all patches"
    return 0
}
