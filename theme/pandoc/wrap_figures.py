#!/bin/env python3

"""
Wrap code blocks and tables in figures, just like images are by default.
"""

import panflute as pf

def prepare(doc):
    doc.in_figure = False
       

def action(el, doc):
    if isinstance(el, pf.RawBlock):
        if "<figure" in el.text: #assuming no nested figures
            doc.in_figure = True
        if "</figure" in el.text:
            doc.in_figure = False
        
    elif isinstance(el, (pf.CodeBlock, pf.Table)) and not doc.in_figure:
        return [
            pf.RawBlock("<figure>"),
            el,
            pf.RawBlock("</figure>")
        ]


def finalize(doc):
    del doc.in_figure


if __name__ == "__main__":
    pf.toJSONFilter(action, prepare, finalize)
