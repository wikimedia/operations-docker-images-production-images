#!/bin/bash
# This is why we should never use bash for scripts. Ever.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
docker run -d -v $DIR/test/config:/etc/mcrouter:ro --name test-mcrouter --rm $1
docker exec test-mcrouter /bin/healthz
RETVAL=$?
docker stop test-mcrouter
exit $RETVAL
