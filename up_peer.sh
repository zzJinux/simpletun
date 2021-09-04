#!/bin/sh

set -eu
# -e: exit on fail
# -u: treat unset variables as an error

if ! { [ $# -eq 2 ] || [ $# -eq 1 ]; }; then
  echo "Usage (example): ./up_peer.sh [--rebuild] 10.0.0.2/24"
  exit 2
fi

REBUILD=
TUN_ADDRESS=

while [ ${1:-} ]; do
  case $1 in
    --rebuild) REBUILD=rebuild;;
    *) TUN_ADDRESS=$1
  esac

  shift
done
if [ ! $TUN_ADDRESS ]; then
  echo "TUN_ADDRESS argument not set"
  exit 2
fi

IMAGE_NAME=tunpeer
ENTRYPOINT_SH=setup_scripts/entrypoint.sh
SETUP_TUN_SH=setup_scripts/setup_tun.sh

# Build a new image if '--rebuild' option is fed or there is no image yet
if [ $REBUILD ] || ! docker image inspect $IMAGE_NAME >/dev/null 2>&1; then
  # Create hardlinks required for buliding the image
  ln "$ENTRYPOINT_SH" tunpeer/entrypoint.sh
  ln "$SETUP_TUN_SH" tunpeer/setup_tun.sh

  # `... || :` effectively disables `set -e`
  { docker build -t $IMAGE_NAME -f tunpeer/Dockerfile ./tunpeer
    buildret=$?; } || :

  # Remove hardlinks
  rm tunpeer/entrypoint.sh;
  rm tunpeer/setup_tun.sh;
  (exit $buildret)
fi

smart_sleep='echo Container started; trap "exit 0" 15; while sleep 1 & wait $!; do :; done'



cont_id=$(docker run --cap-add=NET_ADMIN -v "$PWD/a.out":/workspace/a.out:ro -w /workspace \
  -e TUN_ADDRESS=$TUN_ADDRESS --name=$CONTAINER_NAME $IMAGE_NAME)
ip_addr=$(docker container inspect -f "{{.NetworkSettings.Networks.bridge.IPAddress}}" $cont_id)

echo 'Container ID'
echo -e "\t$cont_id"
echo 'IP Address'
echo -e "\t$ip_addr"

# docker exec -it $CONTAINER_NAME /bin/bash
