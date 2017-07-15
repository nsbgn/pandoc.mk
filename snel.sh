#!/bin/bash

# Wrapper that leverages a `make` recipe into compiling a static website.
# The first argument is the source directory (default: current directory),
# second argument is the destination directory (default: `build` in source)

SNEL="$(dirname "$(readlink --canonicalize $0)")"

SRC="$1"
DEST="${2:-$SRC/build}"

if [[ $SRC ]]; then
    # Execute at least twice: on the first run, the pages are created; on the
    # second, auxiliary files that were referenced in the files are
    # generated
    for TARGET in html resources upload-ftp; do
        cd $SNEL && make \
            SRC="$SRC" \
            DEST="$DEST" \
            "$TARGET" || exit
    done
else 
    echo "\
Usage: 
    snel SOURCE [TARGET]
    
SOURCE: Directory with source files.

TARGET: Build directory. Default: SOURCE/build
"
fi
