#!/bin/bash -x

# If a ZooKeeper container is linked with the alias `zookeeper`, use it.
# You MUST set ZOOKEEPER_IP in env otherwise.
[ -n "$ZOOKEEPER_PORT_2181_TCP_ADDR" ] && ZOOKEEPER_IP=$ZOOKEEPER_PORT_2181_TCP_ADDR
[ -n "$ZOOKEEPER_PORT_2181_TCP_PORT" ] && ZOOKEEPER_PORT=$ZOOKEEPER_PORT_2181_TCP_PORT

IP=$(hostname -i)

# Concatenate the IP:PORT for ZooKeeper to allow setting a full connection
# string with multiple ZooKeeper hosts
[ -z "$ZOOKEEPER_CONNECTION_STRING" ] && ZOOKEEPER_CONNECTION_STRING="${ZOOKEEPER_IP}:${ZOOKEEPER_PORT:-2181}"

# Let see if we can extract the ID from the name, making us K8S stateful set compatible
# expects $HOSTNAME in the format *-DIGIT
[ -z "$KAFKA_BROKER_ID" ] && KAFKA_BROKER_ID=$(echo $HOSTNAME | sed 's/.*-\([0-9]\+\)$/\1/')

cat /kafka/config/server.properties.template | sed \
  -e "s|{{GROUP_MAX_SESSION_TIMEOUT_MS}}|${GROUP_MAX_SESSION_TIMEOUT_MS:-300000}|g" \
  -e "s|{{KAFKA_BROKER_ID}}|${KAFKA_BROKER_ID:-0}|g" \
  -e "s|{{KAFKA_DELETE_TOPIC_ENABLE}}|${KAFKA_DELETE_TOPIC_ENABLE:-false}|g" \
  -e "s|{{LOG_FLUSH_SCHEDULER_INTERVAL_MS}}|${LOG_FLUSH_SCHEDULER_INTERVAL_MS:-9223372036854775807}|g" \
  -e "s|{{LOG_RETENTION_HOURS}}|${LOG_RETENTION_HOURS:-168}|g" \
  -e "s|{{ZOOKEEPER_CONNECTION_STRING}}|${ZOOKEEPER_CONNECTION_STRING}|g" \
  -e "s|{{ZOOKEEPER_CONNECTION_TIMEOUT_MS}}|${ZOOKEEPER_CONNECTION_TIMEOUT_MS:-10000}|g" \
  -e "s|{{ZOOKEEPER_SESSION_TIMEOUT_MS}}|${ZOOKEEPER_SESSION_TIMEOUT_MS:-10000}|g" \
   > /kafka/config/server.properties

# Kafka's built-in start scripts set the first three system properties here, but
# we add two more to make remote JMX easier/possible to access in a Docker
# environment:
#
#   1. RMI port - pinning this makes the JVM use a stable one instead of
#      selecting random high ports each time it starts up.
#   2. RMI hostname - normally set automatically by heuristics that may have
#      hard-to-predict results across environments.
#
# These allow saner configuration for firewalls, EC2 security groups, Docker
# hosts running in a VM with Docker Machine, etc. See:
#
# https://issues.apache.org/jira/browse/CASSANDRA-7087
if [ -z $KAFKA_JMX_OPTS ]; then
    KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote=true"
    KAFKA_JMX_OPTS="$KAFKA_JMX_OPTS -Dcom.sun.management.jmxremote.authenticate=false"
    KAFKA_JMX_OPTS="$KAFKA_JMX_OPTS -Dcom.sun.management.jmxremote.ssl=false"
    KAFKA_JMX_OPTS="$KAFKA_JMX_OPTS -Dcom.sun.management.jmxremote.rmi.port=${KAFKA_JMX_PORT:-7203}"
    KAFKA_JMX_OPTS="$KAFKA_JMX_OPTS -Djava.net.preferIPv4Stack=true"
    KAFKA_JMX_OPTS="$KAFKA_JMX_OPTS -Djava.rmi.server.hostname=${JAVA_RMI_SERVER_HOSTNAME:-$HOSTNAME} "
    export KAFKA_JMX_OPTS
fi

# awful no-good hack for dealing with mounted FS
mkdir /data/data /logs/logs

echo "Starting kafka"
exec /kafka/bin/kafka-server-start.sh /kafka/config/server.properties
