#!/bin/env python3

"""
Script to construct a JSON-formatted table of contents of the current
directory, or of the directory given as its first argument.
"""

import os
import sys
import json
from datetime import datetime
from os.path import join, isdir, isfile, getmtime

"""
Mapping between keys in the JSON dump.
"""
ATTRIBUTES = {
    "title"         : "t",
    "description"   : "a",
    "link"          : "p",
    "children"      : "c",
    "hidden"        : "h",
    "modified"      : "m"
}


def sitemap(**kwargs):
    """
    Construct a dictionary representing a sitemap.
    """

    output = {}
    for key,value in kwargs.items():
        if key in ATTRIBUTES and value:
            output[ATTRIBUTES[key]] = value
    return output

  

def index(path, ignore=[]):
    """
    Return a "table of contents" for a set of documents in a (possibly nested) 
    directory structure on the filesystem. 
    
    :param path: Path to the top-level entry.
    :param ignore: Files or directories to ignore.
    :return: Dictionary that represents a table of contents.
    """

    # When dealing with a directory
    if isdir(path):

        try:
            with open(join(path, "index.md.meta.json"), "r") as f:
                meta = json.load()
        except FileNotFoundError:
            meta={}
            
        # Find all subheaders
        children = filter(None,
            (
                index(subpath) for subpath in sorted(
                    join(path, entry)
                    for entry in os.listdir(path)
                    if not entry.startswith(".")
                    and not entry in ignore
                    and entry != "index.md.meta.json"
                )
                if isdir(subpath) 
                or subpath.endswith(".meta.json")
            )
        )
       
        if children:
            return sitemap(children=list(children), **meta)


    # When dealing with document metadata
    elif isfile(path):

        with open(path, "r") as f:
            meta = json.load(f)

        modified = meta.get("original")
        if modified:
            modified = datetime.fromtimestamp(getmtime(modified))
            modified = modified.strftime("%Y-%m-%dT%H:%M")

        return sitemap(modified=modified, **meta)

    else:
        return None


if __name__ == "__main__":
    try:
        path = sys.argv[1]
    except IndexError:
        path = os.curdir

    main = index(path, ignore=["footer","__pycache__"]) or {}
    footer = index(join(path, "footer"), ignore=["__pychache__"]) or {}
    
    output = [
        main.get(ATTRIBUTES["children"], []), 
        footer.get(ATTRIBUTES["children"], [])
    ]
    
    json.dump(output, sys.stdout, separators=(",", ":"))
