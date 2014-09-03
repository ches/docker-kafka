FROM relateiq/oracle-java7

RUN apt-get update && apt-get install -y \
  ca-certificates wget

RUN mkdir /data /logs /kafka

# Install Kafka binary distribution to /kafka
# Haven't figured out why the .md5 server doesn't like wget, so inlining digest
RUN cd /tmp && \
  wget --progress=dot:mega http://www.us.apache.org/dist/kafka/0.8.1.1/kafka_2.10-0.8.1.1.tgz && \
  echo VERIFY CHECKSUM: && \
  gpg --print-md MD5 kafka_2.10-0.8.1.1.tgz 2>/dev/null && \
  echo 'kafka_2.10-0.8.1.1.tgz: F3 F7 44 67 88 D9 A0 6F  6B FA BA 72 91 2B D8 CF' && \
  tar -zx -C /kafka --strip-components=1 -f kafka_2.10-0.8.1.1.tgz && \
  rm -rf kafka_*

VOLUME [ "/data", "/logs" ]

# primary, jmx
EXPOSE 9092 7203

ADD http://repo1.maven.org/maven2/org/slf4j/slf4j-log4j12/1.7.6/slf4j-log4j12-1.7.6.jar /kafka/lib/slf4j-log4j12.jar
ADD config /kafka/config
ADD start.sh /start.sh

ENV PATH /kafka/bin:$PATH

CMD ["/start.sh"]

