#!/bin/bash
if [ -z ${1+"def"} ]; then
    echo "Usage:"
    echo "$0 <title of article>"
else
    echo "creating post with title $1"
    python3 -m nikola new_post -f markdown -s $1
fi
    
