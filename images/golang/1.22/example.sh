#!/bin/bash

# This should be run with the image to test as an argument, e.g.:
#
# $ images/golang/1.22/example.sh docker-registry.wikimedia.org/golang1.22:1.22
#
# NOTE: While moving this to test.sh may work on your local machine, it will
# fail on the buildhost since it cannot clone from github due to network
# restrictions.
docker run \
    "$1" /bin/bash -c "go version && git clone https://github.com/golang/example/ src/example && cd src/example/hello && go run . Wikimedia && echo OK"
