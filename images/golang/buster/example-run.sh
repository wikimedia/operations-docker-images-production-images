#!/bin/bash
EXAMPLE="github.com/golang/example/outyet"
docker run \
    --volume /"$(pwd)"/log://log \
    docker-registry.wikimedia.org/golang:1.14-1 /bin/bash -c "go get $EXAMPLE && cd src/$EXAMPLE && go build && echo OK"
