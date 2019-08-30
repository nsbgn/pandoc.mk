#!/usr/bin/env python3

import sys
import json
import argparse
from datetime import datetime
from os import curdir, listdir
from os.path import join, isdir, getsize, getmtime

def index(path, metadata_dir, ignore):
    """
    Return a "table of contents" for a set of documents in a (possibly nested)
    directory structure on the filesystem. `tree -J` is similar but does not
    give the flexibility I want.

    :param path: Path to the top-level entry.
    :param ignore: Files or directories to ignore.
    :return: Object representing a table of contents.
    """

    data = \
        { "path" : path
        , "modified": datetime.fromtimestamp(getmtime(path)).strftime("%Y-%m-%d")
        , "size": getsize(path)
        }

    # Add metadata
    if metadata_dir:
        if isdir(path):
            metadata_path = join(metadata_dir, path, "meta.json")
        else:
            metadata_path = join(metadata_dir, path + ".meta.json")

        try:
            with open(metadata_path, "r") as f:
                data["meta"] = json.load(f)
        except FileNotFoundError:
            pass

    # Directories have a "contents" child
    if isdir(path):
        data["contents"] = [ 
            index(path=join(path,child), 
                ignore=ignore,
                metadata_dir=metadata_dir)
            for child in sorted(listdir(path)) 
            if 
                not child in ignore 
                and child != "meta.json" 
                and not child.endswith(".meta.json")
            ]

    return data



if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Make a JSON file tree, including ."
        )
    parser.add_argument(
        "--metadata", 
        metavar="PATH", 
        help="Directory in which to look for metadata. (Same path structures and filenames .meta.json appended)")
    parser.add_argument(
        "--ignore", 
        metavar="PATH", 
        nargs="*", 
        help="Directories to ignore.")
    parser.add_argument(
        "directory", 
        metavar="PATH", 
        help="Target directory.")
    args = parser.parse_args()
    sitemap = index(
        path=args.directory, 
        metadata_dir=args.metadata or curdir, 
        ignore=args.ignore or [])

    json.dump(sitemap, separators=(',',':'), fp=sys.stdout)
    sys.stdout.write('\n')
