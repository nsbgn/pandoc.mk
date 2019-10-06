#!/usr/bin/env python3

"""
This filter adds local images to the "targets" metadata field.
"""

import panflute as pf

def prepare(doc):
    doc.images = []

def action(el, doc):
    if isinstance(el, pf.Image) and el.url \
    and not any(map(el.url.startswith, ("http://","https://","ftp://"))):
        doc.images.append(pf.MetaString(el.url))

def finalize(doc):

    # Add already existing targets
    try:
        doc.images += doc.metadata["targets"].content.list
    except KeyError:
        None

    if doc.images:
        doc.metadata["targets"] = pf.MetaList(*doc.images) 
    del doc.images

if __name__ == "__main__":
    pf.toJSONFilter(action, prepare, finalize)

   
