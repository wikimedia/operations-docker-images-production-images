#!/bin/bash
set -e
# Yes, this is unit testing using bash.
# I understand this will probably be used against me in the future, so here goes the rationale:
# I'm just running curls and greps of docker logs. Writing this in a programming language
# using a testing framework will make sense only once we adopt a testing framework for the
# whole repository.
# In the meantime, bash is enough and actually is faster to write and debug. We're just losing some
# fancy output.

RED=$(tput setaf 1)
NC=$(tput sgr0)

docker_run() {
    docker run -d --rm $@ -p 8080:8080 docker-registry.wikimedia.org/httpd-fcgi
    if [ $? -ne 0 ]; then
        exit 1
    fi
    # Sleep a few seconds to ensure httpd is responding
    sleep 3
}

test_header() {
    curl -Is http://localhost:8080 | grep -qF "$@"
}

test_in_logs() {
    id=$1
    val=$2
    docker logs "$id" 2>&1 | grep -qF "$val"
}

failed_exit() {
    id=$1
    shift
    echo ""
    echo "${RED}$@${NC}"
    echo "Left the docker container up for inspection. When done, please stop it with:"
    echo "docker stop $id"
    /bin/false
}

test_success() {
    echo "PASS"
    docker stop "$1" > /dev/null
}

# TEST 1: vanilla run
echo -n "## Defaults behave as expected "
id=$(docker_run)
if ! test_header 'Server: wikimedia'; then
    failed_exit $id "Failed to find the default Server header"
fi
if test_in_logs $id "proxy:debug"; then
    failed_exit $id "Found debug messages in the logs"
fi
if ! test_in_logs $id "localhost:9000"; then
    failed_exit $id "The default proxy on localhost:9000 is not used"
fi
test_success $id

# TEST 3: debug logs
echo -n "## Enable debug logging    "
id=$(docker_run -e DEBUG=1)
curl localhost:8080 -Is > /dev/null
if ! test_in_logs $id "proxy:debug"; then
    failed_exit $id "Didn't find debug messages in the httpd logs"
fi
test_success $id

# TEST 4: fcgi proxy
echo -n "## Connect to fcgi using a socket  "
id=$(docker_run -e FCGI_MODE=FCGI_UNIX)
curl localhost:8080 -Is > /dev/null
if ! test_in_logs $id "proxy:unix:/run/shared/fpm-www.sock|fcgi://localhost"; then
    failed_exit $id "Didn't find the unix socket in logs"
fi
test_success $id

# TEST 5: server signature
echo -n "## Server signature can be changed "
id=$(docker_run -e SERVER_SIGNATURE=kubernetes1001/mediawiki-app-canary-dwwe22)
if ! test_header 'Server: kubernetes1001/mediawiki'; then
    failed_exit $id "Didn't find the modifed Server: header"
fi
test_success $id