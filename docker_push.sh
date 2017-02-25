#!/bin/bash
#
# Pushes the Docker image to the registry.
#
# Note you must log in and authenticate with the Docker registry
# before using this script.  To do that, say:
#
# docker login $DOCKER_REGISTRY
#

# Change this to your Docker image name.
DOCKER_IMAGE='kukaatx/ches-kafka'
VERSION='0.10.2.0-0'

if [ -z "$DOCKER_REGISTRY" ]; then
  echo "You must set DOCKER_REGISTRY to the host of the Docker registry you are using.  If you want to use DockerHub (the default), that is index.docker.io."
  exit -1
fi

docker tag $DOCKER_IMAGE $DOCKER_REGISTRY/$DOCKER_IMAGE:$VERSION || exit 1
docker push $DOCKER_REGISTRY/$DOCKER_IMAGE:$VERSION

