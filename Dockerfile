# The image runs Oracle Java 8 installed atop the
# ubuntu:trusty (14.04) official image. Docker's official java images are
# OpenJDK-only currently, and the Kafka project, Confluent, and most other
# major Java projects test and recommend Oracle Java for production for optimal
# performance.

FROM ubuntu:trusty
MAINTAINER Ches Martin <ches@whiskeyandgrits.net>

# Install Java.
# https://github.com/dockerfile/java/blob/master/oracle-java8/Dockerfile
RUN \
  apt-get update && apt-get install -y software-properties-common && \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# The Scala 2.11 build is currently recommended by the project.
ENV KAFKA_VERSION=0.10.1.1 \
	KAFKA_SCALA_VERSION=2.11 \
	KAFKA_JMX_PORT=7203
ENV KAFKA_RELEASE_ARCHIVE="kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION}.tgz"

RUN mkdir /kafka /data /logs

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates

# Download Kafka binary distribution
ADD http://www.us.apache.org/dist/kafka/${KAFKA_VERSION}/${KAFKA_RELEASE_ARCHIVE} /tmp/
ADD https://dist.apache.org/repos/dist/release/kafka/${KAFKA_VERSION}/${KAFKA_RELEASE_ARCHIVE}.md5 /tmp/

WORKDIR /tmp

# Check artifact digest integrity
RUN echo VERIFY CHECKSUM: && \
  gpg --print-md MD5 ${KAFKA_RELEASE_ARCHIVE} 2>/dev/null && \
  cat ${KAFKA_RELEASE_ARCHIVE}.md5

# Install Kafka to /kafka
RUN tar -zx -C /kafka --strip-components=1 -f ${KAFKA_RELEASE_ARCHIVE} && \
  rm -rf kafka_*

ADD config /kafka/config
ADD start.sh /start.sh

# Set up a user to run Kafka
RUN groupadd kafka && \
  useradd -d /kafka -g kafka -s /bin/false kafka && \
  chown -R kafka:kafka /kafka /data /logs
USER kafka
ENV PATH /kafka/bin:$PATH
WORKDIR /kafka

ENV GROUP_MAX_SESSION_TIMEOUT_MS="300000" \
  JAVA_RMI_SERVER_HOSTNAME="" \
  KAFKA_BROKER_ID="" \
  KAFKA_DEFAULT_REPLICATION_FACTOR="1" \
  KAFKA_DELETE_TOPIC_ENABLE="false" \
  KAFKA_LOG4J_OPTS="" \
  KAFKA_LOG_FLUSH_SCHEDULER_INTERVAL_MS="9223372036854775807" \
  KAFKA_LOG_RETENTION_HOURS="168" \
  KAFKA_NUM_PARTITIONS="1" \
  KAFKA_RECOVERY_THREADS_PER_DATA_DIR="1" \
  ZOOKEEPER_CONNECTION_STRING="localhost:2181" \
  ZOOKEEPER_CONNECTION_TIMEOUT_MS="10000" \
  ZOOKEEPER_SESSION_TIMEOUT_MS="10000"

# broker, jmx
EXPOSE 9092 ${KAFKA_JMX_PORT}
VOLUME [ "/data", "/logs" ]

CMD ["/start.sh"]

