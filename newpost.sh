#!/bin/bash
if [ -z ${1+"def"} ]; then
    echo "Usage:"
    echo "$0 <name of post file without extension>"
else
    echo "creating post with title $1"
    cd "${0%/*}"
    cd posts
    python3 -m nikola new_post -f markdown -s $1.md
fi
    
