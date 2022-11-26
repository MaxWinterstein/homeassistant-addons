#!/bin/bash

# see https://github.com/home-assistant/builder

# thx https://stackoverflow.com/a/51911626
__usage="
Usage: $(basename $0) [OPTIONS]

Options:
  push              Build all possible and push
  test <arch>       Build for <arch>

Example:
  $(basename $0) test amd64
"

if [[ $1 = "push" ]]; then
    echo 'Build all and push...'
    echo -n "Dockerhub password for maxwinterstein: "
    read -s password
    docker run --privileged \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v $PWD/:/data homeassistant/aarch64-builder \
        --all -t /data --docker-user maxwinterstein --docker-password $password #--docker-hub-check
elif [[ $1 = "test" ]]; then
    arch=${2:-all}
    echo "Build for $arch..."
    sleep 5
    docker run --privileged \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v $PWD/:/data homeassistant/aarch64-builder \
        --$arch --test -t /data
else
    echo "$__usage"
fi
