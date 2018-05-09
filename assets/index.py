#!/bin/env python3

import os
import sys
import bs4 
import json
import argparse
from os.path import join, isdir, isfile, basename


def index(path, ignore=[]):
    """
    Return a "table of contents" for a set of documents in a (possibly nested) 
    directory structure on the filesystem. 
    
    :param path: Path to the top-level entry.
    :param ignore: Files or directories to ignore.
    :return: BeautifulSoup object that represents table of contents.
    """

    # Get metadata
    meta = {}
    if isdir(path):
        try:
            with open(join(path, "index.md.meta.json"), "r") as f:
                meta = json.load(f)
        except FileNotFoundError:
            meta = {"title": basename(path)}
    elif isfile(path):
        with open(path, "r") as f:
            meta = json.load(f)

    # Menu entry
    title = meta.get("title", "untitled")
    if meta.get("link"):
        entry = soup.new_tag("a", href=meta.get("link"))
    else:
        entry = soup.new_tag("span")
    entry.append(title)

    # Children
    if isdir(path):
        ul = soup.new_tag("ul")
        for child in sorted(os.listdir(path)):
            subpath = join(path, child)
            if not child.startswith(".") \
            and not child in ignore \
            and child != "index.md.meta.json" \
            and (isdir(subpath) or subpath.endswith(".meta.json")):

                li = soup.new_tag("li")
                
                (entry_, sub) = index(subpath, ignore)
                li.append(entry_)
                if sub:
                    li.append(sub)
                ul.append(li)

        return (entry, ul)
    else:
        return (entry, None)




if __name__ == "__main__":

    # Get command line arguments
    parser = argparse.ArgumentParser(description="Make an index.html file.")
    parser.add_argument("--template", metavar="PATH", help="Path to template file. Default: Standard input.")
    parser.add_argument("--directory", metavar="PATH", default=os.curdir, help="Target directory.")
    parser.add_argument("--ignore", metavar="PATH", default=[], nargs="*", help="Directories to ignore.")
    args = parser.parse_args()

    # Read soup
    if args.template:
        template = open(args.template, "r")
    else:
        template = sys.stdin
    with template:
        data = template.read()
    soup = bs4.BeautifulSoup(data, "lxml")
    
    # Populate soup 
    body = soup.find("body")
    body.clear()
    nav = soup.new_tag("nav")
    nav["class"]="up"
    div = soup.new_tag("div")

    (title, sub) = index(path=args.directory, ignore=args.ignore)
    div.append(sub)
    nav.append(div)
    body.append(nav)

    # Output
    print(str(soup))
