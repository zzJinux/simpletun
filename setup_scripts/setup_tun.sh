#!/bin/sh
mkdir -p /dev/net
mknod /dev/net/tun c 10 200 \
  && ip tuntap add name tun0 mode tun \
  && ip link set tun0 up \
  && ip addr add $1 dev tun0
