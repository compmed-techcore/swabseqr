#!/bin/sh
# Full image with basespace
# IMG="sha256:2fd0fb50c8a5d8e8161531077310cf009443961a9bc416e1eca24e34f763535f"
# IMG="sha256:0ad4765082c16edfc1f99df8f6ec7967a220133e7085318b04b284695b3649f4"
IMG="test-image"
CONTAINER="test-container"

# clean up
docker container rm ${CONTAINER}
# build image first using:
docker build -t ${IMG} .