#!/bin/env python3

"""
Script to construct a JSON-formatted table of contents of the current
directory, or of the directory given as its first argument.
"""

import os
import sys
import itertools
import collections
import json
import yaml

from datetime import datetime
from os.path import \
    relpath, realpath, dirname, basename, join, splitext,\
    isdir, isfile, getmtime


"""
File that contains metadata for directories
"""
DIRECTORY_METADATA_FILES = (
    "metadata.yaml", "metadata.yml",
    "meta.yaml", "meta.yml"
)


"""
Map that associates extensions of source documents with extensions of output
documents.
"""
EXTENSIONS = {
    ".md": ".html",
    ".html": ".html"
}


"""
A mapping between the sitemap"s Python attributs and corresponding keys in the
JSON dump.
"""
ATTRIBUTES = {
    "title"         : "t",
    "description"   : "a",
    "link"          : "p",
    "children"      : "c",
    "hidden"        : "h",
    "modified"      : "m",
    "subsection"    : "s" # Whether to make a sub-table of contents for this entry 
}


"""
Whether to set the frontpage (link of a header) to the first child if no
appropriately named frontpage file could be found.
"""
ALWAYS_FRONTPAGE = True


"""
Whether to combine subheaders with their parent headers if the subheader would
be the only child.
"""
COLLAPSE_HEADERS = True


"""
String used to format the modification date.
"""
DATE_FORMAT = "%Y-%m-%dT%H:%M"



class sitemap(collections.MutableMapping):
    """
    A sitemap is a dictionary that represents a "table of contents" for a set of
    documents in a (possibly nested) directory structure on the filesystem. 
    """


    def __setattr__(self, attr, value):
        """
        Any attribute recognised as relevant to the table of contens is added
        to the underlying dictionary at the proper index. Note that a value of
        None will result in removal from the dictionary.
        """
        
        try:
            key = ATTRIBUTES[attr]
        except KeyError:
            super().__setattr__(attr, value)
        else:
            if value is None:
                try: # if necessary
                    del self[key]
                except KeyError:
                    pass
            else:
                self[key] = value



    def __getattr__(self, attr):
        """
        Get the value for an attribute. This only gets called when the default
        machanism to find attribute values fails, and thus the attribute is
        expected to refer to one of the keys of the underlying dictionary.
        """
        
        try:
            key = ATTRIBUTES[attr]
        except KeyError:
            raise AttributeError(attr)
        else:
            return self._dict.get(key)



    def __getitem__(self, key):
        """
        Get an item from the underlying dictionary.
        """
        return self._dict[key]



    def __setitem__(self, key, value):
        """
        Set an item of the underlying dictionary.
        """
        self._dict[key] = value



    def __delitem__(self, key):
        """
        Delete an item from the underlying dictionary.
        """
        del self._dict[key]



    def __iter__(self):
        """
        Iterate over the underlying dictionary.
        """
        return iter(self._dict)



    def __len__(self):
        """
        Get the length of the underlying dictionary.
        """
        return len(self._dict)



    def meta(self, key, default=None, inherit=True):
        """
        Access metadata. If `inherit` is True, any metadata that is not set on
        this entry will be inherited from the closest ancestor entry, if
        possible.
        """
        
        result = self._metadata.get(key, default)
        if not result and self._parent and inherit:
            result = self._parent.meta(key, default, inherit)
        return result



    def root(self):
        """
        Return root node of the table of contents.
        """

        if self._parent is None:
            return self
        else:
            return self._parent.root()



    def __init__(self, path, ignore=[], parent=None):
        """
        Create a sitemap entry from a `path`, by recursively descending down
        the directory structure. 

        :param path: Path to the top-level entry.
        :param ignore: Files or directories to ignore.
        :param parent: Leave blank. In recursive calls, keeps track of parent
        sitemap.
        """
        
        self._dict = {}
        self._parent = parent
        self._metadata = load_metadata(path)
      
        self._path = path
        self._directory = dirname(path)
        self._basename, self._extension = splitext(basename(path))
        
        # Relevant regardless of whether this is a document or a directory
        self.title = self.meta("title") or self.meta("header")
        self.description = self.meta("description") or self.meta("abstract")

        # When dealing with a directory
        if isdir(path):

            # Find all candidate subheaders
            subpaths = (
                (join(path, entry),) + splitext(entry)
                for entry in os.listdir(path)
            )

            # Find all relevant subheaders and convert to sitemaps
            # Note that a header must either link to a page or have subheaders of
            # its own, otherwise it is superfluous
            children = filter(lambda child: child.link or child.children,
                (
                    sitemap(subpath, ignore=ignore, parent=self)
                    for subpath, basename, extension in subpaths
                    if (isdir(subpath) or extension in EXTENSIONS)
                    and not (basename.startswith("."))
                    and not (basename + extension) in ignore
                )
            )

            # Sort headers by their metadata"s `index`; & the filename as fallback 
            children = sorted(children, key=lambda child: str(
                child.meta("index", inherit=False) or child._basename
            ))
            
            # Find frontpage, that is, the file with the same name as the
            # parent directory or one that is called `index.md` or similar
            if children:
                frontpage = None
                for i, child in enumerate(children):
                    if child._basename in ("index", self._basename):
                        frontpage = children.pop(i)
                        break

                if frontpage is not None:
                    self.link = frontpage.link
                elif ALWAYS_FRONTPAGE:
                    self.link = children[0].link
          
            # Set subheaders
            if len(children) < 1:
                pass
            elif len(children) == 1 and COLLAPSE_HEADERS:
                self._dict = leftjoin(self._dict, children[0]._dict)
                self._metadata = leftjoin(children[0]._metadata,self._metadata)
            elif not self.meta("toplevel"):
                self.children = children


        # When dealing with a document
        else:

            # Note last changed date
            modified = datetime.fromtimestamp(getmtime(path))
            self.modified = modified.strftime(DATE_FORMAT)

            # Link to the corresponding output document
            rootname, extension = splitext(
                relpath(path, start=self.root()._path)
            )
            self.link = rootname + EXTENSIONS.get(extension.lower(), "")



def leftjoin(*dictionaries):
    """
    Combine dictionaries by recursively left-joining them.  
    """
    
    result = {}
    for key, value in itertools.chain(*map(dict.items, dictionaries)):
        try:
            current = result[key]
        except KeyError:
            result[key] = value
        else:
            if isinstance(current, dict) and isinstance(value, dict):
                result[key] = leftjoin(current, value)
    return result




def load_metadata(path):
    """
    Load all metadata relevant to the document or directory at `path`.
    
    For documents, this is mostly compatible with metadata blocks as defined
    for [Pandoc](http://pandoc.org/MANUAL.html#metadata-blocks). Additionally,
    directories may have "global" metadata in a special file `metadata.yaml`.

    Note: Only YAML blocks at the beginning of the file are recognised.
    """


    # TODO: I can just do pandoc -t html5 --template=templtest.json example/02-example.md
    # Maybe combine with `jq` to have both target dumps to be parsed into a
    # single file?
    
    def delimiter(line, char):
        return len(line) > 3 and len(line.rstrip(char)) == 0

    if os.path.isdir(path):
        mpaths = (join(path, mfile) for mfile in DIRECTORY_METADATA_FILES)
        return leftjoin(
            *(load_metadata(mpath) for mpath in mpaths if isfile(mpath))
        )

    metadata = {}

    with open(path, "r", encoding="utf-8") as handle:
        yaml_block = None
        unused_headers = ["title", "author", "date"]
        current_header = None
        
        for line in (line.rstrip() for line in handle):

            if yaml_block is None:
                if delimiter(line, "-"):
                    yaml_block = []
                elif line.startswith("%") and unused_headers:
                    current_header = unused_headers.pop(0)
                    metadata[current_header] = line[1:].strip()
                elif line.startswith("\s") and current_header:
                    metadata[current_header] += "\n" + line
                elif line:
                    break

            else:
                if delimiter(line, "-") or delimiter(line, "."):
                    break
                else:
                    yaml_block.append(line)

        if yaml_block:
            metadata = leftjoin(metadata, yaml.safe_load("\n".join(yaml_block)))

    print(metadata, file=sys.stderr)
    return metadata



if __name__ == "__main__":
    path = os.curdir
    try:
        path = sys.argv[1]
    except IndexError:
        pass

    path = realpath(path)
    path_footer = join(path, "footer")

    main = footer = None
    if isdir(path):
        main = sitemap(path, ignore=["build", "dist", "footer", "__pycache__"]).children
    if isdir(path_footer):
        footer = sitemap(path_footer, ignore=["__pychache__"]).children

    # Dump sitema to JSON so as to act as an input to `index.js`.
    json.dump(
        [main or [], footer or []],
        sys.stdout,
        default=dict,
        #indent=4, sort_keys=True,
        separators=(",", ":")
    )
