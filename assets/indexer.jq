#!/usr/bin/env jq
# This is a collection of filters for `jq`, intended to manipulate JSON objects
# into JSON representing a website index, for further processing in a template.

# Select the descendant described by the array of names in `$path`.
def descend($path):
    if ($path | length) > 0
    then
        .contents[]? | select(.name == $path[0]) | descend($path[1:])
    else
        .
    end
;

# Insert a child element at a particular path.
# Like `setpath/2`, but instead of making objects like `{"a":{"b":{…}}}`, this
# makes objects like `{"contents":[{"name":"a", "contents":[{"name":"b",…}]}]}`
# I don't really like this function, because it's so verbose. Making a path
# expression for updating with the |= operator (see `descend/1`) doesn't seem
# to work when it is recursive?
def insert($path; $child):
    if ($path | length) > 0
    then
        if ([.contents[]? | select(.name == $path[0])] | length) > 0
        then
            (.contents[] | select(.name == $path[0])) |= (. | insert($path[1:]; $child))
        else
            (.contents = [.contents[]?] + [{"name":$path[0]} | insert($path[1:];$child)])
        end
    else
        . * $child
    end
;


# Merge together `filetree.json` and `*.meta.json` files, with behaviour
# depending on the filename of the object. Use with the `--null-input` switch.
def process_files:
    reduce inputs as $input
        (   {}
        ;   ($input | input_filename) as $f |
            if ($f | endswith(".meta.json")) then 
                insert
                ( $f | ltrimstr($prefix) | rtrimstr(".meta.json") | split("/")
                ; {"meta": $input} )
            else 
                reduce $input[] as $entry
                ( .
                ;   insert
                    ( $entry.path | split("/")
                    ; $entry )
                )
            end
        )
;


# Adds links to each page object. The link should be the same as the path,
# except in the case of directories, which may either link to its index.md, to
# a page with meta.frontmatter==true, or have no link at all. If there is only
# one child to a page, perhaps it should collapse onto its parent.
# Also not great.
def add_links:
    if (.path and (.path | endswith(".md")))
    then
        .link = (.path | rtrimstr(".md") | . + ".html")
    else
        ([ .contents[]? | add_links ] | group_by(.name=="index.md")) as $partition 
        |   ($partition[0] // []) as $contentfiles
        |   ($partition[1] // []) as $indexfiles
        |   if ($indexfiles + $contentfiles | length) == 0 then 
                .
            elif ($indexfiles | length) == 0 then
                .contents = $contentfiles
            else
                $indexfiles[0] as $index
                | .contents = $contentfiles + $indexfiles[1:]
                | .link = $index.link
            end
    end
;

# A draft should not show up in the table of contents.
def take_drafts:
    "wip"
;

# Resources are images and other things that should not be part of the table of
# contents - anything that is neither a directory nor has metadata.
def take_resources:
    "wip"
;

# Combines the given stream of JSON objects by merging them, and performs the
# given operations to turn it into a proper index.
def index:
    process_files
    | add_links
;
