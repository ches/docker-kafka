FROM relateiq/oracle-java7

RUN apt-get update
RUN apt-get install -y wget

RUN mkdir /data /logs /kafka
RUN wget --no-check-certificate --progress=dot:mega -O - https://s3-us-west-1.amazonaws.com/relateiq-build-resources/kafka-0.7.1-incubating-src.tgz | tar -zx -C /kafka --strip-components=1
RUN cd kafka && ./sbt update
RUN cd kafka && ./sbt package

VOLUME [ "/data", "/logs" ]

# primary, jmx
EXPOSE 9092 7203

CMD ["kafka/start.sh"]

ADD server.properties kafka/config/server.properties.tmpl
ADD start.sh kafka/start.sh
