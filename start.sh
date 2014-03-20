#!/bin/bash

# Necessary?
export JMX_PORT=7203

echo "ZOOKEEPER_IP=$ZOOKEEPER_PORT_2181_TCP_ADDR"

echo "Fixing ZOOKEEPER_IP in server.properties"
sed -i "s/{{ZOOKEEPER_IP}}/${ZOOKEEPER_PORT_2181_TCP_ADDR:-localhost}/g" /kafka/config/server.properties

echo "Starting kafka"
/kafka/bin/kafka-server-start.sh /kafka/config/server.properties 2>&1 | tee /logs/kafka.log
