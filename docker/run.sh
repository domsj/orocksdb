#!/bin/bash
set -ue
[[ ${JENKINS_PARAM-} =~ shell_trace ]] && set -x

IMAGE=$1
shift

docker build --rm=true \
       --tag=orocksdb_$IMAGE \
       --build-arg HOST_UID=$UID \
       -f docker/$IMAGE/Dockerfile ./docker/ \


       if [ -t 1 ];
then TTY="-t";
else TTY="";
fi

docker run -i $TTY --privileged=true \
       --env HOST_UID=$UID \
       --env JENKINS_PARAM="${JENKINS_PARAM-}" \
       --env TRAVIS \
       --ulimit core=-1 \
       -v ${PWD}:/home/jenkins/orocksdb \
       orocksdb_$IMAGE \
       "$@"
