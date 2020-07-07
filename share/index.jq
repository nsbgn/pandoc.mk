#!/usr/bin/env jq
# This is a collection of filters for `jq`, intended to manipulate JSON objects
# into JSON representing a website index, for further processing in a template.

# Convert "truthy" value to actual boolean.
def bool:
    (. == {} or . == [] or . == false or . == null or . == 0) | not
;


# Generate this object and all its children.
def all_children:
    ., ((.contents? // empty) | .[] | all_children)
;


# Format a date into its wordy equivalent.
def format_date:
    try
    (
        (   try (. | strptime("%Y-%m-%d")) 
            catch (
                try (. | strptime("%Y/%m/%d")) 
                catch (
                    try (. | strptime("%Y-%m"))
                )
            )
        ) | mktime | strftime("%B %-d, %Y")
    )
;


# Group an array of objects into an object of arrays, such that the key-value
# pairs of the new object are an accumulation of those of the old object. For
# example, `[{"a":1, "b":2}, {"a":3}]` turns into `{"a":[1, 3], "b":[3]}`. This
# can be used to partition an array.
# Try: `[1,"2",3] | map ({(.|type):.}) | group`
def group:
    reduce ([.[] | to_entries[]] | group_by(.key))[] as $group
    ( {} 
    ; .[ $group[0].key ] |= (. // []) + [ $group[].value ] 
    )
;


# Wrap an object in other objects so that the original object exists at a
# particular "path". Like `{} | setpath(["a","b"], …)`, but instead of making
# objects like `{"a":{"b":…}}`, this makes objects like `{"name":"a",
# "contents":[{"name":"b",…}]}`.
def tree($path):
    def tree_aux($future):
        { "name": $future[0] } + 
        if ($future | length) > 1 then
            { "contents": [ tree_aux($future[1:]) ] }
        else
            .
        end
    ;
    tree_aux($path)
;


# Merge two values. If the values are both objects, the values at equal indices
# will be recursively merged; if the values are both arrays, the arrays are
# concatenated; if the values are some other type, we only check if the values
# do not conflict.
def merge(other): 
    if (. | type) == "object" and (other | type) == "object" then
        (. | to_entries) + (other | to_entries) 
        | group_by(.key)
        | map({ "key": (.[0].key), "value" : (reduce .[1:][].value as $x (.[0].value; merge($x)))})
        | from_entries
    elif (. | type) == "array" and (other | type) == "array" then
        . + other
    elif . == other then
        .
    else
        error("trying to merge incompatible objects " + (.|type) + " and " + (other|type))
    end
;


# Merge an array of content by grouping it by name and then merging all the
# pages with the same name. This is necessary because simply merging content
# will only concatenate pages, even if they are the same page.
def merge_content:
    reduce .[] as $x ({}; merge($x)) |
    if has("contents") then
        .contents |= ( group_by(.name) | map(merge_content) )
    else
        .
    end
;


# Add paths to each object, that is, the names of the ancestors.
def add_directories:
    def add_directories_aux($history):
        ($history + [.name]) as $present |
        .directory = $history |
        (.contents[]? |= add_directories_aux($present))
    ;
    add_directories_aux([])
;


# Any page gets a link to its target.
def add_links(target_extension):
    if (has("directory") and (.name | endswith(".md"))) then
        .link = ((.directory + [.name]) | join("/") | rtrimstr(".md") | . + "." + target_extension)
    else
        .contents[]? |= add_links(target_extension)
    end
;


# Front matter is the page to be associated with the enclosing directory rather
# than itself.
def add_frontmatter:
    if has("contents") then
        ( .contents | map({(.name=="index.md" or .meta.frontmatter|tostring):.}) | group) as {$true, $false}
        | .frontmatter = $true[0]
        | .contents = (($false // []) + $true[1:])
        | (.contents[] |= add_frontmatter)
    else
        .
    end
;


# To remove an object, we first mark it for removal, then actually remove it
# later. It would be nicer if we could just do `all_children ... |= empty`,
# which works in some cases but not all. I suppose it has to do with changing
# objects as we are iterating over them.
def mark:
    .marked_for_removal = true
;

# Remove all objects marked for removal.
def remove_marked:
    if .marked_for_removal? == true
    then empty
    else (.contents? // empty) |= map(remove_marked)
    end
;



# Drafts can be excluded from being uploaded and included in the table of
# contents. To not count as a draft, a document should be explicitly marked as
# "publish" in the metadata.
def add_drafts:
    ( ( all_children | select((has("contents") or .external or .meta.publish | bool) | not)) |= mark) | remove_marked
;


# A resource is anything that is neither a directory nor a page with metadata
# nor an external link.
def add_resources:
    if has("contents") then
        ( .contents | map({(has("contents") or has("meta") or (has("external") and (.external | bool))|tostring):.}) | group) as {$true, $false}
        | .contents = ($true // [])
        | .resources = ($false // [])
        | (.contents[]? |= add_resources)
    else
        .
    end
;


# Sort content first according to sort order in metadata.
def sort_content:
    (all_children | select(has("contents")) | .contents) |= (
        sort_by(.meta.sort // .meta.title // .name)
    )
;


# Add a note that tells us whether this has only children who have no more
# subchildren.
def annotate_leaves:
    (all_children | select(has("contents"))) |= (
        .only_leaves = (.contents | all(has("contents") | not))
    )
;


# Combines the given stream of JSON objects by merging them, and performs the
# given operations to turn it into a proper index.
def index(target_extension):
    merge_content
    | add_directories
    | add_links(target_extension)
    | add_drafts
    | add_frontmatter
    | add_resources
    | sort_content
    | annotate_leaves
;


# Get publishable targets from an index
def targets:
    recurse(.contents[]?)
    | ., (.frontmatter // empty)
    | select(has("link") and (has("external") | not)) 
    | .directory as $dir 
    | [.link] + [.targets?[] | $dir + [.] | join("/") ] 
    | .[]
;
