#!/usr/bin/env jq
# This is a collection of filters for `jq`, intended to manipulate JSON objects
# into JSON representing a website index, for further processing in a template.

# Convert "truthy" value to actual boolean.
def bool:
    (. == {} or . == [] or . == false or . == null or . == 0) | not
;

# Group the values of properties of an array of objects. For example, [{"a":1,
# "b":2}, {"a":3}] turns into {"a":[1, 3], "b":[3]}. This can be used to
# partition an array; try, for example:
# [1,2,3,4] | map({(if .%2==0 then "even" else "odd" end):.}) | group
def group:
    reduce ([.[] | to_entries[]] | group_by(.key))[] as $group
    ( {} 
    ; .[ $group[0].key ] |= (. // []) + [ $group[].value ] 
    )
;

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

def classify_frontmatter:
    [ .[] | { ( if .name == "index.md" or .meta.frontmatter then "frontmatter" else "contents" end ) : . }] 
    | group
    | .contents |= (. // [])
    | .frontmatter |= (. // [])
;

def classify_draft:
    [.[] | { (if .meta.draft then "drafts" else "contents" end ) : . }]
    | group
    | .contents |= (. // [])
    | .drafts |= (. // [])
;

def classify_resource:
    [ .[] | { ( if (.meta | bool) or (.contents | bool) then "contents" else "resources" end ) : . }] 
    | group
    | .contents |= (. // [])
    | .resources |= (. // [])
;

def add_links:
    if (.path and (.path | endswith(".md")))
    then
        .link = (.path | rtrimstr(".md") | . + ".html")
    else
        .contents[]? |= add_links
    end
;

def add_frontmatter:
    if .contents | bool then
        . + (.contents | classify_frontmatter | (.contents[]? |= add_frontmatter) )
    else
        .
    end
;

def add_drafts:
    if .contents | bool then
        . + (.contents | classify_draft | (.contents[]? |= add_drafts))
    else
        .
    end
;

# Resources are images and other things that should not be part of the table of
# contents - anything that is neither a directory nor has metadata.
def add_resources:
    if .contents | bool then
        . + (.contents | classify_resource | (.contents[]? |= add_resources))
    else
        .
    end;

# Combines the given stream of JSON objects by merging them, and performs the
# given operations to turn it into a proper index.
def index:
    process_files
    | add_links
    | add_frontmatter
    | add_drafts
    | add_resources
;
