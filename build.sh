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
# OS=ubuntu                               # string - OS image namespace - required
# OS_ARCHIVE=xenial-20181005              # string - OS image tag - required
# TOOL_VARIANT=git                        # string - variant to build - required
# TAG_LATEST=true                         # bool - tag image with `:latest` - optional
# BASE_REGISTRY_NAMESPACE=library         # string - user or organization namespace of base image - required
# BUILD_REGISTRY_NAMESPACE=startersclan   # string - user or organization namespace for build image - required
# BUILD_IMAGE_NAME=steamcmd               # string - build image namespace - required
# TAG_TOOL_ARCHIVE=                       # string - release tag - optional

#############################  End of CI variables  ##############################

# Process user variables
if [ -n "${TAG_TOOL_ARCHIVE}" ]; then
    DOCKERHUB_REGISTRY_USER=${DOCKERHUB_REGISTRY_USER:?err}
    DOCKERHUB_REGISTRY_PASSWORD=${DOCKERHUB_REGISTRY_PASSWORD:?err}
fi

# Process job variables
OS=${OS:?err}
OS_ARCHIVE=${OS_ARCHIVE:?err}
TOOL_VARIANT=${TOOL_VARIANT:?err}
TAG_LATEST=${TAG_LATEST:-}
BASE_REGISTRY_NAMESPACE=${BASE_REGISTRY_NAMESPACE:?err}
BUILD_REGISTRY_NAMESPACE=${BUILD_REGISTRY_NAMESPACE:?err}
BUILD_IMAGE_NAME=${BUILD_IMAGE_NAME:?err}
TAG_TOOL_ARCHIVE=${TAG_TOOL_ARCHIVE:-}

# Process default job variables
BASE_IMAGE_NAME="$OS"
BASE_TAG_FULL="$OS_ARCHIVE"
BUILD_TAG_FULL="$TOOL_VARIANT"
BUILD_CONTEXT="variants/$TOOL_VARIANT"

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

# Login to docker registry
if [ -n "${TAG_TOOL_ARCHIVE}" ]; then
    echo "${DOCKERHUB_REGISTRY_PASSWORD}" | docker login -u "${DOCKERHUB_REGISTRY_USER}" --password-stdin
fi

echo "OS: $OS"
echo "OS_ARCHIVE: $OS_ARCHIVE"
echo "TOOL_VARIANT: $TOOL_VARIANT"
echo "TAG_LATEST: $TAG_LATEST"
echo "BASE_REGISTRY_NAMESPACE: $BASE_REGISTRY_NAMESPACE"
echo "BASE_IMAGE_NAME: $BASE_IMAGE_NAME"
echo "BASE_TAG_FULL: $BASE_TAG_FULL"
echo "BUILD_REGISTRY_NAMESPACE: $BUILD_REGISTRY_NAMESPACE"
echo "BUILD_IMAGE_NAME: $BUILD_IMAGE_NAME"
echo "BUILD_TAG_FULL: $BUILD_TAG_FULL"
echo "BUILD_CONTEXT: $BUILD_CONTEXT"
echo "BASE_IMAGE: ${BASE_REGISTRY_NAMESPACE}/${BASE_IMAGE_NAME}:${BASE_TAG_FULL}"
echo "BUILD_IMAGE: ${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}"
echo "TAG_TOOL_ARCHIVE: $TAG_TOOL_ARCHIVE"

# Build image
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
if [ -n "${TAG_TOOL_ARCHIVE}" ]; then
    docker tag "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}" "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${TOOL_VARIANT}-${TAG_TOOL_ARCHIVE}"
fi
docker images
docker inspect "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}"
docker history "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}"

# Test image
docker run -t --rm --entrypoint /bin/bash "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}:${BUILD_TAG_FULL}" -c "printenv && ls -al && exec steamcmd.sh +login anonymous +quit"

# Push image
if [ -n "${TAG_TOOL_ARCHIVE}" ]; then
    docker push -a "${BUILD_REGISTRY_NAMESPACE}/${BUILD_IMAGE_NAME}"
fi

# Clean-up
if [ -n "${TAG_TOOL_ARCHIVE}" ]; then
    docker logout
fi
