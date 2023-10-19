#!/bin/bash
docker run \
    docker-registry.wikimedia.org/golang1.21:1.21 /bin/bash -c "git clone https://github.com/golang/example/ src/example && cd src/example/hello && go run . Wikimedia && echo OK"
