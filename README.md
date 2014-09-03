Apache Kafka on Docker
======================

This repository holds a build definition and supporting files for building a
[Docker] image to run [Kafka] in containers. It is published as an Automated
Build [on the Docker registry], as `ches/kafka`.

Configuration is parameterized, enabling a Kafka cluster to be run from multiple
container instances.

### Fork Note

This image/repo was forked from [relateiq/kafka]. The changes are:

- Change the Kafka binary source to an official Apache artifact. RelateIQ's was
  on a private S3 bucket, and this opaqueness is not suitable for a
  publicly-shared image for reasons of trust.
- Changes described in [this pull request](https://github.com/relateiq/docker-kafka/pull/4).

If these differences resolve in time, I will deprecate this build repo but
leave existing published images on the registry.

Usage Quick Start
-----------------

Here is a minimal-configuration example running the Kafka broker service, then
using the container as a client to run the basic producer and consumer example
from [the Kafka Quick Start]:

```
$ docker run -d --name zookeeper jplock/zookeeper:3.4.6
$ docker run -d --name kafka --link zookeeper:zookeeper ches/kafka

$ ZK_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' zookeeper)
$ KAFKA_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' kafka)

$ docker run --rm ches/kafka \
>   kafka-topics.sh --create --topic test \
>     --replication-factor 1 --partitions 1 --zookeeper $ZK_IP:2181
Created topic "test".

# In separate terminals:
$ docker run --rm --interactive ches/kafka \
>   kafka-console-producer.sh --topic test --broker-list $KAFKA_IP:9092
<type some messages followed by newline>

$ docker run --rm ches/kafka \
>   kafka-console-consumer.sh --topic test --from-beginning --zookeeper $ZK_IP:2181
```

### Volumes

The container exposes two volumes that you may wish to bind-mount, or process
elsewhere with `--volumes-from`:

- `/data`: Path where Kafka's data is stored (`log.dirs` in Kafka configuration)
- `/logs`: Path where Kafka's logs (`INFO` level) will be written, via log4j

### Ports and Linking

The container publishes two ports:

- `9092`: Kafka's standard broker communication
- `7203`: JMX publishing, for e.g. jconsole or VisualVM connection

Kafka requires Apache ZooKeeper. You can satisfy the dependency by simply
linking another container that exposes ZooKeeper on its standard port of 2181,
as shown in the above example, **ensuring** that you link using an alias of
`zookeeper`.

Alternatively, you may configure a specific address for Kafka to find ZK. See
the Configuration section below.

### A more complex local development setup

This example shows more configuration options and assumes that you wish to run a
development environment with Kafka ports mapped directly to localhost, for
instance if you're writing a producer or consumer and want to avoid rebuilding a
container for it to run in as you iterate. This requires that localhost is your
Docker host, i.e. your workstation runs Linux. If you're using something like
boot2docker, substitute the value of `boot2docker ip` below.

```bash
$ mkdir -p kafka-ex/{data,logs} && cd kafka-ex
$ docker run -d --name zookeeper --publish 2181:2181 jplock/zookeeper:3.4.6
$ docker run -d \
    --hostname localhost
    --name kafka \
    --volume ./data:/data --volume ./logs:/logs \
    --publish 9092:9092 --publish 7203:7203 \
    --env EXPOSED_HOST=127.0.0.1 --env ZOOKEEPER_IP=127.0.0.1 \
    ches/kafka
```

Configuration
-------------

Some parameters of Kafka configuration can be set through environment variables
when running the container (`docker run -e VAR=value`). These are shown here
with their default values, if any:

- `BROKER_ID=0`

  Maps to Kafka's `broker.id` setting. Must be a unique integer for each broker
  in a cluster.
- `PORT=9092`

  Maps to Kafka's `port` setting. The port that the broker service listens on.
  You will need to explicitly publish a new port from container instances if you
  change this.
- `EXPOSED_HOST=<container's IP within docker0's subnet>`

  Maps to Kafka's `advertised.host.name` setting. Kafka brokers gossip the list
  of brokers in the cluster to relieve producers from depending on a ZooKeeper
  library. This setting should reflect the address at which producers can reach
  the broker on the network, i.e. if you build a cluster consisting of multiple
  physical Docker hosts, you will need to set this to the hostname of the Docker
  *host's* interface where you forward the container `PORT`.
- `EXPOSED_PORT=9092`

  As above, for the port part of the advertised address. Maps to Kafka's
  `advertised.port` setting. If you run multiple broker containers on a single
  Docker host and need them to be accessible externally, this should be set to
  the port that you forward to on the Docker host.
- `ZOOKEEPER_IP=<taken from linked "zookeeper" container, if available>`

  **Required** if no container is linked with the alias "zookeeper" and
  publishing port 2181. Used in constructing Kafka's `zookeeper.connect`
  setting.
- `ZOOKEEPER_PORT=2181`

  Used in constructing Kafka's `zookeeper.connect` setting.
- `CHROOT`, ex: `/v0_8_1`

  ZooKeeper root path used in constructing Kafka's `zookeeper.connect` setting.
  This is blank by default, which means Kafka will use the ZK `/`. You should
  set this if the ZK instance/cluster is shared by other services, or to
  accommodate Kafka upgrades that change schema. However, as of 0.8.1.1 Kafka
  will *not* create the path in ZK automatically, you must ensure it exists
  before starting brokers.


[Docker]: http://www.docker.io
[Kafka]: http://kafka.apache.org
[on the Docker registry]: https://registry.hub.docker.com/u/ches/kafka/
[relateiq/kafka]: https://github.com/relateiq/docker-kafka
[the Kafka Quick Start]: http://kafka.apache.org/documentation.html#quickstart

