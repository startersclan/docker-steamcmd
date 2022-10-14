#!/bin/sh

#################################  CI variables  #################################
# Use this section for local builds.
# All variables regardless of type will be processed as strings in builds.
# Types specified in comments but serve to aid users in populating said variables.
##################################################################################

## User variables ##
# DOCKERHUB_REGISTRY_USER=                # string - docker hub username - required
# DOCKERHUB_REGISTRY_PASSWORD=            # string - docker hub password or api key - required

## build variables ##
# BASE_IMAGE_NAME=ubuntu                               # string - OS image namespace - required
# BASE_IMAGE_TAG=xenial-20181005              # string - OS image tag - required
# BUILD_IMAGE_VARIANT=git                        # string - variant to build - required
# TAG_LATEST=true                         # bool - tag image with `:latest` - optional
# BASE_REGISTRY_NAMESPACE=library         # string - user or organization namespace of base image - required
# BUILD_REGISTRY_NAMESPACE=startersclan   # string - user or organization namespace for build image - required
# BUILD_IMAGE_NAME=steamcmd               # string - build image namespace - required
# RELEASE_TAG_REF=                       # string - release tag - optional

#############################  End of CI variables  ##############################

# Process user variables
if [ -n "${RELEASE_TAG_REF}" ]; then
    DOCKERHUB_REGISTRY_USER=${DOCKERHUB_REGISTRY_USER:?err}
    DOCKERHUB_REGISTRY_PASSWORD=${DOCKERHUB_REGISTRY_PASSWORD:?err}
fi

# Process job variables
BASE_IMAGE_NAME=${BASE_IMAGE_NAME:?err}
BASE_IMAGE_TAG=${BASE_IMAGE_TAG:?err}
BUILD_IMAGE_VARIANT=${BUILD_IMAGE_VARIANT:?err}
TAG_LATEST=${TAG_LATEST:-}
BASE_REGISTRY_NAMESPACE=${BASE_REGISTRY_NAMESPACE:?err}
BUILD_REGISTRY_NAMESPACE=${BUILD_REGISTRY_NAMESPACE:?err}
BUILD_IMAGE_NAME=${BUILD_IMAGE_NAME:?err}
RELEASE_TAG_REF=${RELEASE_TAG_REF:-}

# Process default job variables
BASE_TAG_FULL="$BASE_IMAGE_TAG"
BUILD_TAG_FULL="$BUILD_IMAGE_VARIANT"
BUILD_CONTEXT="variants/$BUILD_IMAGE_VARIANT"

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
if [ -n "${RELEASE_TAG_REF}" ]; then
    echo "${DOCKERHUB_REGISTRY_PASSWORD}" | docker login -u "${DOCKERHUB_REGISTRY_USER}" --password-stdin
fi

# Print job variables
echo "BASE_IMAGE_NAME: $BASE_IMAGE_NAME"
echo "BASE_IMAGE_TAG: $BASE_IMAGE_TAG"
echo "BUILD_IMAGE_VARIANT: $BUILD_IMAGE_VARIANT"
echo "TAG_LATEST: $TAG_LATEST"
echo "BASE_REGISTRY_NAMESPACE: $BASE_REGISTRY_NAMESPACE"
echo "BASE_TAG_FULL: $BASE_TAG_FULL"
echo "BUILD_REGISTRY_NAMESPACE: $BUILD_REGISTRY_NAMESPACE"
echo "BUILD_IMAGE_NAME: $BUILD_IMAGE_NAME"
echo "BUILD_TAG_FULL: $BUILD_TAG_FULL"
echo "BUILD_CONTEXT: $BUILD_CONTEXT"
echo "BASE_IMAGE: ${BASE_REGISTRY_NAMESPACE}/${BASE_IMAGE_NAME}:${BASE_TAG_FULL}"
echo "BUILD_IMAGE: ${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}"
echo "RELEASE_TAG_REF: $RELEASE_TAG_REF"

# Build the image
date
time docker pull "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}" || true
time docker build \
    --cache-from "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}" \
    -t "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}" \
    --build-arg BASE_IMAGE="${BASE_REGISTRY_NAMESPACE}/${BASE_IMAGE_NAME}:${BASE_TAG_FULL}" \
    --label "game_distributor=steamcmd" \
    "$BUILD_CONTEXT"
if [ "${TAG_LATEST}" = 'true' ]; then
    docker tag "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}" "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:latest"
fi
if [ -n "${RELEASE_TAG_REF}" ]; then
    docker tag "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}" "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_IMAGE_VARIANT}-${RELEASE_TAG_REF}"
fi
docker images
docker inspect "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}"
docker history "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}"

# Test the image
docker run -t --rm --entrypoint /bin/bash "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}" -c "printenv && ls -al && exec steamcmd.sh +login anonymous +quit"

# Push the image
if [ -n "${RELEASE_TAG_REF}" ]; then
    docker push -a "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}"
fi

# Docker registry logout
if [ -n "${RELEASE_TAG_REF}" ]; then
    docker logout
fi
