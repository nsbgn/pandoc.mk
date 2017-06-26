#!/usr/bin/env python3

"""
This filter puts references in the metadata, so that they can be
relocated in the template.
"""

# TODO: Do the same for footnotes, somehow

import panflute as pf

def prepare(doc):
    doc.references = None
     
def action(el, doc):
    if isinstance(el, pf.Div) and el.identifier == "refs":
        doc.references = list(el.content)
        return []

def finalize(doc):
    if doc.references:
        doc.metadata["references"] = pf.MetaBlocks(*doc.references) 
    del doc.references

if __name__ == "__main__":
    pf.toJSONFilter(action, prepare, finalize)

   
