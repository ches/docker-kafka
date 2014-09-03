Apache Kafka on Docker
======================

This repository holds a build definition and supporting files for building a
[Docker] image to run [Kafka] in containers. It is published as an Automated
Build [on the Docker registry], as `relateiq/kafka`.

Configuration is parameterized, enabling a Kafka cluster to be run from multiple
container instances.

Usage Quick Start
-----------------

Here is a minimal-configuration example running the Kafka broker service, then
using the container as a client to run the basic producer and consumer example
from [the Kafka Quick Start]:

```
$ docker run -d --name zookeeper jplock/zookeeper:3.4.6
$ docker run -d --name kafka --link zookeeper:zookeeper relateiq/kafka

$ ZK_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' zookeeper)
$ KAFKA_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' kafka)

$ docker run --rm relateiq/kafka \
>   /kafka/bin/kafka-topics.sh --create --topic test \
>     --replication-factor 1 --partitions 1 --zookeeper $ZK_IP:2181
Created topic "test".

# In separate terminals:
$ docker run --rm --interactive relateiq/kafka \
>   /kafka/bin/kafka-console-producer.sh --topic test --broker-list $KAFKA_IP:9092
<type some messages followed by newline>

$ docker run --rm relateiq/kafka \
>  /kafka/bin/kafka-console-consumer.sh --topic test --from-beginning --zookeeper $ZK_IP:2181
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
    relateiq/kafka
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


RelateIQ Deployment
-------------------

### Provisioning

```bash
knife ec2 server create -N 'usw2a-kafka4-prod' -r 'role[base], recipe[apt], recipe[raid]' -E 'prod' -x 'ubuntu' -f m1.xlarge -I 'ami-8eea71be' -Z 'us-west-2a' --region 'us-west-2' -g 'sg-57f21538' -s 'subnet-eb6b619f' -S 'us-west-2-chef2' --ephemeral '/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde' -i ~/.chef/us-west-2-chef2.pem --no-host-key-verify

knife ec2 server create -N 'usw2b-kafka4-prod' -r 'role[base], recipe[apt], recipe[raid]' -E 'prod' -x 'ubuntu' -f m1.xlarge -I 'ami-8eea71be' -Z 'us-west-2b' --region 'us-west-2' -g 'sg-57f21538' -s 'subnet-1a38b172' -S 'us-west-2-chef2' --ephemeral '/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde' -i ~/.chef/us-west-2-chef2.pem --no-host-key-verify

knife ec2 server create -N 'usw2c-kafka4-prod' -r 'role[base], recipe[apt], recipe[raid]' -E 'prod' -x 'ubuntu' -f m1.xlarge -I 'ami-8eea71be' -Z 'us-west-2c' --region 'us-west-2' -g 'sg-57f21538' -s 'subnet-fa7f4abc' -S 'us-west-2-chef2' --ephemeral '/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde' -i ~/.chef/us-west-2-chef2.pem --no-host-key-verify
```

### Build

```bash
docker build -t "kafka":0.8.1.1 .
```

```bash
docker run -d -t -e EXPOSED_PORT=9092 -e  -p 9092:9092 relateiq/kafka
docker run -d -v /mnt/apps/kafka8/data:/data -v /mnt/apps/kafka8/logs:/logs --name kafka8 -P -e BROKER_ID=1 -e CHROOT=/v0_8_1_1 -h localhost --link zookeeper:zookeeper relateiq/kafka:0.8.1.1
```

```bash
knife bootstrap 10.30.10.148 -x ubuntu -N 'usw2b-kafka2-prod' -r 'recipe[apt],recipe[raid],role[base]' -E 'prod' -i ~/.ssh/usw2-docker.pem --sudo
knife bootstrap 10.30.30.22  -x ubuntu -N 'usw2c-kafka1-prod' -r 'recipe[apt],recipe[raid],role[base]' -E 'prod' -i ~/.ssh/usw2-docker.pem --sudo

docker run -rm -t -i -link kafka:kafka7 -link kafka8:kafka8 -link zookeeper:zookeeper kafka-migration bash

sudo docker run -d -v /mnt/apps/kafka8/data:/data -v /mnt/apps/kafka8/logs:/logs --name kafka8 -p 9093:9093 -e EXPOSED_PORT=9093 -e BROKER_ID=0 -e CHROOT=/v0_8_1_1 --link zookeeper:zookeeper relateiq/kafka:0.8.1.1
```

### Local

```bash
sudo docker run -d \
  --hostname localhost
  --name kafka8 \
  --volume ./data:/data --volume ./logs:/logs \
  --publish 9092:9092 --publish 7203:7203 \
  --env EXPOSED_HOST=localhost --env ZOOKEEPER_IP=127.0.0.1 \
  kafka:0.8.1.1
```

### Staging

```bash
sudo docker run -d -v /mnt/apps/kafka/data:/data -v /mnt/apps/kafka/logs:/logs -h $(hostname) --name kafka8 -p 9092:9092 -p 7203:7203 -e EXPOSED_HOSTNAME=usw2b-kafka2-staging.amz.relateiq.com -e EXPOSED_PORT=9092 -e BROKER_ID=1 -e CHROOT=/v0_8_1_1 -e ZOOKEEPER_IP=10.30.10.192 kafka:0.8.1
```

### Prod

```bash
sudo docker run -d -v /mnt/apps/kafka/data:/data -v /mnt/apps/kafka/logs:/logs -h $(hostname) --name kafka8 -p 9092:9092 -p 7203:7203 -e EXPOSED_HOSTNAME=usw2c-kafka4-prod.amz.relateiq.com -e EXPOSED_PORT=9092 -e BROKER_ID=1 -e CHROOT=/v0_8_1_1 -e ZOOKEEPER_IP=10.30.10.24 kafka:0.8.1.1

sudo docker run -d -v /mnt/apps/kafka/data:/data -v /mnt/apps/kafka/logs:/logs -h $(hostname) --name kafka8 -p 9092:9092 -p 7203:7203 -e EXPOSED_HOSTNAME=usw2b-kafka4-prod.amz.relateiq.com -e EXPOSED_PORT=9092 -e BROKER_ID=2 -e CHROOT=/v0_8_1_1 -e ZOOKEEPER_IP=10.30.10.24 kafka:0.8.1.1

sudo docker run -d -v /mnt/apps/kafka/data:/data -v /mnt/apps/kafka/logs:/logs -h $(hostname) --name kafka8 -p 9092:9092 -p 7203:7203 -e EXPOSED_HOSTNAME=usw2a-kafka4-prod.amz.relateiq.com -e EXPOSED_PORT=9092 -e BROKER_ID=3 -e CHROOT=/v0_8_1_1 -e ZOOKEEPER_IP=10.30.10.24 kafka:0.8.1.1
```

[Docker]: http://www.docker.io
[on the Docker registry]: https://registry.hub.docker.com/u/relateiq/kafka/
[Kafka]: http://kafka.apache.org
[the Kafka Quick Start]: http://kafka.apache.org/documentation.html#quickstart

