#!/usr/bin/env python3

"""
This filter wraps the document in <main> tags with footers and headers, and
relocates the reference section.
"""

import panflute as pf
from datetime import datetime


def meta(doc, key):
    """
    Get string value of document's metadata.
    """

    value = doc.get_metadata(key)
    return pf.stringify(value) if value else ""



def format_date(date):
    """
    Transform string date from 2000-01-01 format into 1 January 2000 format,
    if possible.
    """
    
    try:
        date = datetime.strptime(date, "%Y-%m-%d").strftime("%-d %B %Y")
    except (ValueError, TypeError):
        pass
    return date



def wrap_main(doc):
    """
    Wrap the document in <main> tags, decorated with metadata in a footer.
    """
    
    abstract = meta(doc, "abstract") or meta(doc, "description")
    if abstract:
        abstractDiv = pf.Div(pf.Plain(pf.Str(abstract)), classes=["abstract"])
    else:
        abstractDiv = pf.Null()


    doc.content = ([
        pf.RawBlock('<main>'),
        abstractDiv,
    ] + list(doc.content) + [
        pf.RawBlock('<footer>&mdash; {}</footer></main>'.format(
            ",".join(filter(None, [
                meta(doc, "author") or "Anonymous",
                format_date(meta(doc, "date"))
            ]))
        ))
    ])



    
def extract_refs(el, doc):
    """
    Lift the <div> with references out of the document so that it can be 
    reinserted as a <section> later on.
    """
    
    if isinstance(el, pf.Div) and el.identifier == "refs":
        doc.references = list(el.content)
        return []



def insert_refs(doc):
    """
    Re-insert the extracted references as a <section> tag.
    """
    if doc.references:
        doc.content = (
            list(doc.content) +
            [ pf.RawBlock('<section class="references">') ] +
            list(doc.references) +
            [ pf.RawBlock("</section>") ]
        )



def prepare(doc):
    doc.references = []
    
    
def action(el, doc):
    return extract_refs(el, doc)


def finalize(doc):
    wrap_main(doc)
    insert_refs(doc)
    del doc.references


if __name__ == "__main__":
    pf.toJSONFilter(action, prepare, finalize)
