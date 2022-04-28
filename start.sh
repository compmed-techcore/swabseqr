#!/bin/sh
SWAB_DIR="/mnt/bigdata/compmed/swabseq/" # this needs to be hard coded
# Full image with basespace
# IMG="sha256:2fd0fb50c8a5d8e8161531077310cf009443961a9bc416e1eca24e34f763535f"
# IMG="sha256:0ad4765082c16edfc1f99df8f6ec7967a220133e7085318b04b284695b3649f4"
IMG="test-image"
CONTAINER="test-container"
# still want a local directory

# build image first using:
# docker build -t ${IMG} .
# docker run -it --name devtest --mount type=bind,source=$SWAB_DIR,target="/data/Covid/swabseq2/remote" --mount source="local_mirror",target="/data/Covid/swabseq2/localmirror" --mount source="bcls_local",target="/data/Covid/swabseq2/bcls" $IMG
docker container run -it \
    --mount type=bind,source="/mnt/bigdata/compmed/swabseq",target="/data/Covid/swabseq2/remote" \
    --mount source="local_mirror",target="/data/Covid/swabseq2/localmirror" \
    --mount source="bcls_local",target="/data/Covid/swabseq2/bcls" \
    --name ${CONTAINER} ${IMG}

