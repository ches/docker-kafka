#!/bin/bash -x

# If a ZooKeeper container is linked with the alias `zookeeper`, use it.
# You MUST set ZOOKEEPER_IP in env otherwise.
[ -n "$ZOOKEEPER_PORT_2181_TCP_ADDR" ] && ZOOKEEPER_IP=$ZOOKEEPER_PORT_2181_TCP_ADDR
[ -n "$ZOOKEEPER_PORT_2181_TCP_PORT" ] && ZOOKEEPER_PORT=$ZOOKEEPER_PORT_2181_TCP_PORT

IP=$(cat /etc/hosts | head -n1 | awk '{print $1}')

cat /kafka/config/server.properties.template \
  | sed "s|{{ZOOKEEPER_IP}}|${ZOOKEEPER_IP}|g" \
  | sed "s|{{ZOOKEEPER_PORT}}|${ZOOKEEPER_PORT:-2181}|g" \
  | sed "s|{{ZOOKEEPER_CHROOT}}|${ZOOKEEPER_CHROOT:-}|g" \
  | sed "s|{{KAFKA_BROKER_ID}}|${KAFKA_BROKER_ID:-0}|g" \
  | sed "s|{{KAFKA_ADVERTISED_HOST_NAME}}|${KAFKA_ADVERTISED_HOST_NAME:-$IP}|g" \
  | sed "s|{{KAFKA_PORT}}|${KAFKA_PORT:-9092}|g" \
  | sed "s|{{KAFKA_ADVERTISED_PORT}}|${KAFKA_ADVERTISED_PORT:-9092}|g" \
   > /kafka/config/server.properties

export JMX_PORT=7203

echo "Starting kafka"
exec /kafka/bin/kafka-server-start.sh /kafka/config/server.properties
