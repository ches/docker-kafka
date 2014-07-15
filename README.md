Running
=======

```build
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

### Staging

```bash
sudo docker run -d -v /mnt/apps/kafka/data:/data -v /mnt/apps/kafka/logs:/logs -h $(hostname) --name kafka8 -p 9092:9092 -p 7203:7203 -e EXPOSED_HOSTNAME=usw2b-kafka2-staging.amz.relateiq.com -e EXPOSED_PORT=9092 -e BROKER_ID=1 -e CHROOT=/v0_8_1_1 -e ZOOKEEPER_PORT_2181_TCP_ADDR=10.30.10.192 kafka:0.8.1
```

### Prod


```bash
sudo docker run -d -v /mnt/apps/kafka/data:/data -v /mnt/apps/kafka/logs:/logs -h $(hostname) --name kafka8 -p 9092:9092 -p 7203:7203 -e EXPOSED_HOSTNAME=usw2c-kafka1-prod.amz.relateiq.com -e EXPOSED_PORT=9092 -e BROKER_ID=1 -e CHROOT=/v0_8_1_1 -e ZOOKEEPER_PORT_2181_TCP_ADDR=10.30.10.24 kafka:0.8.1.1

sudo docker run -d -v /mnt/apps/kafka/data:/data -v /mnt/apps/kafka/logs:/logs -h $(hostname) --name kafka8 -p 9092:9092 -p 7203:7203 -e EXPOSED_HOSTNAME=usw2b-kafka2-prod.amz.relateiq.com -e EXPOSED_PORT=9092 -e BROKER_ID=2 -e CHROOT=/v0_8_1_1 -e ZOOKEEPER_PORT_2181_TCP_ADDR=10.30.10.24 kafka:0.8.1.1

sudo docker run -d -v /mnt/apps/kafka/data:/data -v /mnt/apps/kafka/logs:/logs -h $(hostname) --name kafka8 -p 9092:9092 -p 7203:7203 -e EXPOSED_HOSTNAME=usw2a-kafka3-prod.amz.relateiq.com -e EXPOSED_PORT=9092 -e BROKER_ID=3 -e CHROOT=/v0_8_1_1 -e ZOOKEEPER_PORT_2181_TCP_ADDR=10.30.10.24 kafka:0.8.1.1
```