FROM debian:buster

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get -y install ncat

COPY ./entrypoint.sh /
COPY ./setup_tun.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD echo Container started; trap "exit 0" 15; while sleep 3600 & wait $!; do :; done
