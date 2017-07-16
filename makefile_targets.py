"""
Filter that dumps the local links in a document to a file
"""

import sys
import panflute as pf
from urllib.parse import urlparse
from os.path import abspath, relpath, join


def prepare(doc):
    doc.files = set()


def action(el, doc):
    if isinstance(el, (pf.Image, pf.Link)):
        url = urlparse(el.url, scheme="file")
        if url.path and not url.netloc:
            path = url.path

            if not path.startswith("/"):
                destination = doc.get_metadata("destination")
                prefix = doc.get_metadata("path")
                path = join(destination, prefix, path)
          
            doc.files.add(path)


def finalize(doc):
    dump = doc.get_metadata("target-dump")
    if dump and doc.files:
        with open(dump, "w") as handle:
            for fn in doc.files:
                handle.write(fn + "\n")
    del doc.files


if __name__ == "__main__":
    pf.toJSONFilter(action, prepare, finalize)
