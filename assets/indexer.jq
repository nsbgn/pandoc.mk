def pred: 
    .key != "meta" and (.value | type == "object");

def arr:
    if type == "object" 
    then (to_entries | map(select(pred) | .value | arr)) as $sub
         | with_entries(select(pred | not)) | .contents = $sub
    else
        .
    end; 

def filetree:
    reduce inputs as $i ({}; ($i.path | split("/") ) as $p | setpath($p;
    getpath($p) + ($i | .name |= $p[-1:][0])));

def filetree_meta:
    if (input_filename | endswith(".meta.json")) 
    then 
        . as $i 
        | (input_filename | ltrimstr($prefix) | rtrimstr(".meta.json") | split("/")) as $p
        | {} 
        | setpath($p + ["meta"]; $i) 
    else 
        .
    end;

def index:
    reduce .[] as $i ({}; $i * .) | arr;
