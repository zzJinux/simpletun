#!/bin/sh
SETUP_TUN="$(dirname "$0")/setup_tun.sh"
$SETUP_TUN $TUN_ADDRESS >/setup_tun.sh.log 2>&1
exec "$@"
