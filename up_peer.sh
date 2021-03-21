#!/bin/sh

set -eu
# -e: exit on fail
# -u: treat unset variables as an error

err_handler() {
  [ $? -eq 0 ] && exit
  echo "Failed at $1" >&2
}
trap 'err_handler $LINENO' EXIT


IMAGE_NAME=tunpeer
CONTAINER_NAME=tunnel_peer
ENTRYPOINT_SH=setup_scripts/entrypoint.sh
SETUP_TUN_SH=setup_scripts/setup_tun.sh
TUN_ADDRESS=10.0.0.1/24

if [ ${1:-} ]; then
  TUN_ADDESS=$1
fi

# Build a new image if '--rebuild' option is fed or there is no image yet
if [ "${1:-}" = '--rebuild' ] || ! docker image inspect $IMAGE_NAME >/dev/null 2>&1; then
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

image_id=$(docker image inspect --format='{{.Id}}' $IMAGE_NAME)
cont_image_id=$(docker container inspect --format='{{.Image}}' $CONTAINER_NAME 2>/dev/null || :)

if [ "$cont_image_id" != "$image_id" ]; then
  # Either the container does not exist or the container's image is outdated.

  if [ $cont_image_id ]; then
    # The container's image is outdated.

    echo "Stopping and removing the old container"
    docker stop $CONTAINER_NAME >/dev/null && docker rm $_ >/dev/null
  fi

  echo 'Creating a container'
  docker create --cap-add=NET_ADMIN -v "$PWD/a.out":/workspace/a.out:ro -w /workspace \
    -e TUN_ADDRESS=$TUN_ADDRESS --name=$CONTAINER_NAME $IMAGE_NAME
fi

cont_status=$(docker container inspect --format='{{.State.Status}}' $CONTAINER_NAME 2>/dev/null)

if [ "$cont_status" != 'running' ]; then
  echo 'Starting the container'
  docker start $CONTAINER_NAME
fi


exec docker exec -it $CONTAINER_NAME /bin/bash
