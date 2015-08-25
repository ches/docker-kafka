## latest / 0.8.2.1-1 - Unreleased

- Allow more flexible configuration of ZooKeeper connection string so that a ZK
  cluster can be used. ([androa], #4)

## 0.8.2.1 - 24 August, 2015

- Updated to Kafka 0.8.2.1
- Switch base image to `netflixoss/java:7`. `relateiq/oracle-java7` does not
  tag its images, which is rather annoying for build consistency, and further,
  they changed it to basing on `ubuntu:14.10` which is not a Long Term Support
  release. In my opinion non-LTS versions are not suitable for production
  server usage.
- Fix JMX connectivity by pegging RMI port.
- Cleaned up the `start.sh` script to remove RelateIQ dev particularities.
- Changed EXPOSE env var names to ADVERTISED to better match Kafka config
  properties.

## 0.8.1.1-1 - 4 September, 2014

- Adds /kafka/bin to PATH for more convenient use of tools like `kafka-topics.sh`
- Creates a `kafka` user to own the service process and data
- Fixes slf4j-log4j not loading--typo on adding jar to classpath

## 0.8.1.1

Initial build with Kafka 0.8.1.1 from official binary distribution.


[androa]: https://github.com/androa
