#!/bin/bash
EXAMPLE="github.com/golang/example/outyet"
docker run \
    --volume /"$(pwd)"/log://log \
    docker-registry.wikimedia.org/golang1.19:1.19-1 /bin/bash -c "go get $EXAMPLE && cd src/$EXAMPLE && go build && echo OK"
