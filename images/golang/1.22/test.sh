#!/bin/bash
docker run \
    "$1" /bin/bash -c "go version && git clone https://github.com/golang/example/ src/example && cd src/example/hello && go run . Wikimedia && echo OK"
