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


# Merge together `filetree.json` and `*.meta.json` files, as given in the
# format produced by `file_entries`.
def combine_files:
    reduce (to_entries | .[]) as $entry
        (   {}
        ;   . * (
            if ($entry.key | endswith(".meta.json"))
            then 
                ( $entry.key 
                    | ltrimstr($prefix)
                    | rtrimstr(".meta.json")
                    | split("/")
                ) as $path
                | insert($path; {"meta": $entry.value})
            else 
                reduce $entry.value[] as $f
                ( .
                ; insert($f.path | split("/"); $f)
                )
            end
            )
        )
;

# Make an object out of a stream of files, associating the each filename with
# its contents. Use with the `--null-input` switch.
def file_entries:
    reduce inputs as $input
        ( {}
        ; . + { ($input | input_filename) : $input }
        )
;

# Adds links to each page object. The link should be the same as the path,
# except in the case of directories, which may either link to its index.md or
# have no link at all. If there is only one child to a page, perhaps it should
# collapse onto its parent.
# Also not great.
def add_links:
    if (.path and (.path | endswith(".md")))
    then
        .link = (.path | rtrimstr(".md") | . + ".html")
    else
        [.contents[]? | add_links] as $newcontents 
        |   [ $newcontents[] | select(.name=="index.md") ] as $indexfiles
        |   [ $newcontents[] | select(.name!="index.md") ] as $otherfiles
        |   if ($newcontents | length) == 0 then 
                .
            elif ($indexfiles | length) == 0 then
                .contents = $newcontents
            else
                $indexfiles[0] as $index
                | .contents = $otherfiles + $indexfiles[1:]
                | .link = $index.link
            end
    end
;

# Combines the given stream of JSON objects by merging them, and performs the
# given operations to turn it into a proper index.
def index:
    file_entries
    | combine_files
    | add_links
;
