#!/bin/bash
#
# As Home Assistant parses the Add-On configuration towards /data/options.json 
# we want all its values as environment variables.
#
# This needs to be sourced ($ source $0)



# TODO: Find a way to use bashio and source together

if [ ! -f '/data/options.json' ]; then
     echo 'ERROR: /data/options.json not found' >>/dev/stderr
     exit 1
fi

# export add-on configuration so it can be sourced and used as login var
for s in $(cat /data/options.json | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" ); do
    export $s
done