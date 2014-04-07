FROM relateiq/oracle-java7

RUN apt-get update && apt-get install -y \
  ca-certificates \
  wget

RUN mkdir /data /logs /kafka

RUN wget --progress=dot:mega -O - https://s3-us-west-1.amazonaws.com/relateiq-build-resources/kafka-0.8.1.tar.gz | tar -zx -C /kafka --strip-components=1
RUN cd kafka && ./gradlew jar

VOLUME [ "/data", "/logs" ]

# primary, jmx
EXPOSE 9092 7203

CMD ["/start.sh"]

ADD config /kafka/config
ADD start.sh /start.sh
