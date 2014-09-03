#!/bin/bash -x

# Necessary?

EXTENSION=""
case $BRANCH in
  master)
    EXTENSION=".prod"
    CHROOT="/v0_8_1"

    # TODO Service discovery
    ZOOKEEPER_PORT=${ZOOKEEPER_PORT:-2181}
  ;;
  staging)
    EXTENSION=".staging"
    CHROOT="/v0_8_1"

    # TODO Service discovery
    ZOOKEEPER_PORT=${ZOOKEEPER_PORT:-2181}
  ;;
  *)
    # Developer environments, etc.
    EXTENSION=".default"
    [ -z "$EXPOSED_HOST" ] && EXPOSED_HOST="127.0.0.1"
    ZOOKEEPER_IP=$ZOOKEEPER_PORT_2181_TCP_ADDR
    ZOOKEEPER_PORT=$ZOOKEEPER_PORT_2181_TCP_PORT

  ;;
esac

IP=$(cat /etc/hosts | head -n1 | awk '{print $1}')
PORT=9092

cat /kafka/config/server.properties${EXTENSION} \
  | sed "s|{{ZOOKEEPER_IP}}|${ZOOKEEPER_IP}|g" \
  | sed "s|{{ZOOKEEPER_PORT}}|${ZOOKEEPER_PORT}|g" \
  | sed "s|{{BROKER_ID}}|${BROKER_ID:-0}|g" \
  | sed "s|{{CHROOT}}|${CHROOT:-}|g" \
  | sed "s|{{EXPOSED_HOST}}|${EXPOSED_HOST:-$IP}|g" \
  | sed "s|{{PORT}}|${PORT:-9092}|g" \
  | sed "s|{{EXPOSED_PORT}}|${EXPOSED_PORT:-9092}|g" \
   > /kafka/config/server.properties

export CLASSPATH=$CLASSPATH:/kafka/lib/slf4j-log4j12.jar
export JMX_PORT=7203

echo "Starting kafka"
exec /kafka/bin/kafka-server-start.sh /kafka/config/server.properties
