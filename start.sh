#!/bin/sh
SWAB_DIR="/Volumes/swabseq"
docker run -it --name devtest --mount type=bind,source=$SWAB_DIR,target="/data/Covid/swabseq2/remote" --mount source="local_mirror",target="/data/Covid/swabseq2/localmirror" --mount source="bcls_local",target="/data/Covid/swabseq2/bcls" main