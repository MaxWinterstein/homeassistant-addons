#!/bin/bash
#
# As Home Assistant parses the Add-On configuration towards /data/options.json 
# we want all its values as environment variables.
#
# This needs to be sourced ($ source $0)

CONFIG=$(curl -s -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" -H "Content-Type: application/json" http://supervisor/core/api/config)
LAT=$(echo $CONFIG | jq '.latitude')
LON=$(echo $CONFIG | jq '.longitude')
ELE=$(echo $CONFIG | jq '.elevation')

# TODO: Find a way to use bashio and source together

if [ ! -f '/data/options.json' ]; then
     echo 'ERROR: /data/options.json not found' >>/dev/stderr
     exit 1
fi

# export add-on configuration so it can be sourced and used as env vars later
# thx https://stackoverflow.com/a/48513046/635876
while read -rd $'' line
do
    if [[ $line == *"HOMEASSISTANT_LATITUDE" ]] || [[ $line == *"HOMEASSISTANT_LONGITUDE" ]] || [[ $line == *"HOMEASSISTANT_ELEVATION" ]]; then
        line=$(echo $line | sed "s/HOMEASSISTANT_LATITUDE/$LAT/")
        line=$(echo $line | sed "s/HOMEASSISTANT_LONGITUDE/$LON/")
        line=$(echo $line | sed "s/HOMEASSISTANT_ELEVATION/$ELE/")
    fi
    # echo $line
    export "$line"
done < <(jq -r <<<"$(cat /data/options.json)" \
         'to_entries|map("\(.key)=\(.value)\u0000")[]')