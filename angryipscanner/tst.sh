docker run \
  --rm \
  -it \
  --name builder \
  --privileged \
  -v "$PWD":/data \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  ghcr.io/home-assistant/amd64-builder \
  -t /data \
  --amd64 \
  --test \
  -i "my-test-addon-{arch}" \
  -d local
