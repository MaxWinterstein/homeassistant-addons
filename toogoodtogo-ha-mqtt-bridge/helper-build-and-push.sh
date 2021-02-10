#!/bin/bash

# see https://github.com/home-assistant/builder

if [[ $1 = "push" ]]; then
    echo 'build and push...'
    sleep 5
    echo -n Dockerhub password for maxwinterstein: 
    read -s password
    echo
    docker run --privileged \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v $PWD/:/data homeassistant/amd64-builder \
        --all -t /data --docker-user maxwinterstein --docker-password $password #--docker-hub-check
else
    echo 'Just testing...'
    sleep 5
    docker run --privileged -v ~/.docker:/root/.docker \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v $PWD/:/data homeassistant/amd64-builder \
        --amd64 --test -t /data
fi
