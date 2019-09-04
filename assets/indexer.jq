#!/usr/bin/env jq
# This is a collection of filters for `jq`, intended to manipulate JSON objects
# into JSON representing a website index, for further processing in a template.


# This is a predicate that returns true if an entry produced by `to_entries` is
# to be considered a child file, and false if it is to be considered a property
# of the file or directory.
def pred: 
    .key != "meta" and (.value | type == "object")
;

# Given a JSON object that contains keys representing both child files and file
# properties, this function leaves the file properties intact and moves the
# child files to a separate array at the "contents" key.
def move_children_to_array:
    if type == "object" 
    then (to_entries | map(select(pred) | .value | move_children_to_array)) as $sub
         | with_entries(select(pred | not)) | .contents = $sub
    else
        .
    end
; 

# Given a stream of JSON objects of the form {"path":"a/b",…}, this function creates
# a single JSON object of the form {"path":"a", "a":{"path": "a/b"}}
def filetree:
    reduce inputs as $i 
        ( {}
        ; ($i.path | split("/")) as $p 
        | setpath($p; getpath($p) + ($i | .name |= $p[-1:][0]))
        )
;

# Given a set of JSON object files, this uses the filename to add them into a
# format similar to the one produced by the `filetree` function.
def filetree_meta:
    if (input_filename | endswith(".meta.json")) 
    then 
        . as $i 
        | (input_filename | ltrimstr($prefix) | rtrimstr(".meta.json") | split("/")) as $p
        | {} 
        | setpath($p + ["meta"]; $i) 
    else 
        .
    end
;

# Adds links to each page object. The link should be the same as the path,
# except in the case of directories, which may either link to its index.md or
# have no link at all. If there is only one child to a page, perhaps it should
# collapse onto its parent.
def add_links:
    "work in progress"
;

# Combines the given stream of JSON objects by merging them, and performs the
# given operations to turn it into a proper index.
def index:
    reduce .[] as $i ({}; $i * .) | move_children_to_array;
