#!/bin/sh

#################################  CI variables  #################################
# Use this section for local builds.
# All variables regardless of type will be processed as strings in builds.
# Types specified in comments but serve to aid users in populating said variables.
##################################################################################

## User variables ##
# DOCKERHUB_REGISTRY_USER=                  # string - docker hub username - required
# DOCKERHUB_REGISTRY_PASSWORD=              # string - docker hub password or api key - required

## build variables ##
# BASE_REGISTRY_NAMESPACE=library           # string - base image user or organization namespace - required
# BASE_IMAGE_NAME=ubuntu                    # string - OS image namespace - required
# BASE_IMAGE_TAG=xenial-20181005            # string - OS image tag - required
# BUILD_REGISTRY_NAMESPACE=startersclan     # string - build image user or organization namespace - required
# BUILD_IMAGE_NAME=steamcmd                 # string - build image namespace - required
# BUILD_IMAGE_VARIANT=git                   # string - variant to build - required
# TAG_LATEST=true                           # bool - tag image with `:latest` - optional
# RELEASE_TAG_REF=                          # string - release tag - optional

#############################  End of CI variables  ##############################

# Process user variables
if [ -n "$RELEASE_TAG_REF" ]; then
    DOCKERHUB_REGISTRY_USER=${DOCKERHUB_REGISTRY_USER:?err}
    DOCKERHUB_REGISTRY_PASSWORD=${DOCKERHUB_REGISTRY_PASSWORD:?err}
fi

# Process job variables
BASE_REGISTRY_NAMESPACE=${BASE_REGISTRY_NAMESPACE:?err}
BASE_IMAGE_NAME=${BASE_IMAGE_NAME:?err}
BASE_IMAGE_TAG=${BASE_IMAGE_TAG:?err}
BUILD_REGISTRY_NAMESPACE=${BUILD_REGISTRY_NAMESPACE:?err}
BUILD_IMAGE_NAME=${BUILD_IMAGE_NAME:?err}
BUILD_IMAGE_VARIANT=${BUILD_IMAGE_VARIANT:?err}
TAG_LATEST=${TAG_LATEST:-}
RELEASE_TAG_REF=${RELEASE_TAG_REF:-}

# Process default job variables
BASE_IMAGE_TAG_FULL="$BASE_IMAGE_TAG"
BUILD_IMAGE_TAG_FULL="$BUILD_IMAGE_VARIANT"
BASE_IMAGE="$BASE_REGISTRY_NAMESPACE/$BASE_IMAGE_NAME:$BASE_IMAGE_TAG_FULL"
BUILD_IMAGE="$BUILD_REGISTRY_NAMESPACE/$BUILD_IMAGE_NAME:$BUILD_IMAGE_TAG_FULL"
BUILD_CONTEXT="variants/$BUILD_IMAGE_VARIANT"
if [ -n "$TAG_LATEST" ]; then
    BUILD_IMAGE_LATEST="$BUILD_REGISTRY_NAMESPACE/$BUILD_IMAGE_NAME:latest"
fi
if [ -n "$RELEASE_TAG_REF" ]; then
    BUILD_IMAGE_RELEASE="$BUILD_REGISTRY_NAMESPACE/$BUILD_IMAGE_NAME:$BUILD_IMAGE_TAG_FULL-$RELEASE_TAG_REF"
fi

# Display system info
hostname
whoami
cat /etc/*release
lscpu
free
df -h
pwd
docker info
docker version

# Terminate the build on errors
set -e

# Docker registry login
if [ -n "$RELEASE_TAG_REF" ]; then
    echo "$DOCKERHUB_REGISTRY_PASSWORD" | docker login -u "$DOCKERHUB_REGISTRY_USER" --password-stdin
fi

# Print job variables
echo "BASE_REGISTRY_NAMESPACE: $BASE_REGISTRY_NAMESPACE"
echo "BASE_IMAGE_NAME: $BASE_IMAGE_NAME"
echo "BASE_IMAGE_TAG: $BASE_IMAGE_TAG"
echo "BUILD_REGISTRY_NAMESPACE: $BUILD_REGISTRY_NAMESPACE"
echo "BUILD_IMAGE_NAME: $BUILD_IMAGE_NAME"
echo "BUILD_IMAGE_VARIANT: $BUILD_IMAGE_VARIANT"
echo "TAG_LATEST: $TAG_LATEST"
echo "BASE_IMAGE_TAG_FULL: $BASE_IMAGE_TAG_FULL"
echo "BUILD_IMAGE_TAG_FULL: $BUILD_IMAGE_TAG_FULL"
echo "BUILD_CONTEXT: $BUILD_CONTEXT"
echo "BASE_IMAGE: $BASE_IMAGE"
echo "BUILD_IMAGE: $BUILD_IMAGE"
if [ -n "$TAG_LATEST" ]; then
    echo "BUILD_IMAGE_LATEST: $BUILD_IMAGE_LATEST"
fi
if [ -n "$RELEASE_TAG_REF" ]; then
    echo "RELEASE_TAG_REF: $RELEASE_TAG_REF"
    echo "BUILD_IMAGE_RELEASE: $BUILD_IMAGE_RELEASE"
fi

# Build the image
date
time docker pull "$BUILD_IMAGE" || true
time docker build \
    --cache-from "$BUILD_IMAGE" \
    -t "$BUILD_IMAGE" \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    --label 'game_distributor=steamcmd' \
    "$BUILD_CONTEXT"
if [ "$TAG_LATEST" = 'true' ]; then
    docker tag "$BUILD_IMAGE" "$BUILD_IMAGE_LATEST"
fi
if [ -n "$RELEASE_TAG_REF" ]; then
    docker tag "$BUILD_IMAGE" "$BUILD_IMAGE_RELEASE"
fi
docker images
docker inspect "$BUILD_IMAGE"
docker history "$BUILD_IMAGE"

# Test the image
docker run -t --rm --entrypoint /bin/bash "$BUILD_IMAGE" -c 'printenv && ls -al && exec steamcmd.sh +login anonymous +quit'

# Push the image
if [ -n "$RELEASE_TAG_REF" ]; then
    docker push "$BUILD_IMAGE"
    if [ -n "$TAG_LATEST" ]; then
        docker push "$BUILD_IMAGE_LATEST"
    fi
    docker push "$BUILD_IMAGE_RELEASE"
fi

# Docker registry logout
if [ -n "$RELEASE_TAG_REF" ]; then
    docker logout
fi
