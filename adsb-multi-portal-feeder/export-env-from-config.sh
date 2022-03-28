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

# export add-on configuration so it can be sourced and used as env vars later
# thx https://stackoverflow.com/a/48513046/635876
while read -rd $'' line
do
    export "$line"
done < <(jq -r <<<"$(cat /data/options.json)" \
         'to_entries|map("\(.key)=\(.value)\u0000")[]')