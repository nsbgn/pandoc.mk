#!/bin/bash
# Output a directory tree as JSON

find ../example -mindepth 1 -printf '{"path":"%P","type":"%y","size":%s,"modified":"%TY-%Tm-%Td"}\n' \
    | jq --null-input \
'       reduce inputs as $i 
        (   {}
        ;   ( $i.path | split("/") ) as $p | setpath($p; getpath($p) + $i)
        )
'

find build/.cache/metadata -iname '*.meta.json' \
    | xargs jq '{(input_filename | rtrimstr(".meta.json")):.}' \
    | jq --slurp 'reduce .[] as $i ({}; . + $i)'
