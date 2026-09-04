#!/bin/bash
# This is why we should never use bash for scripts. Ever.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo 'test123' | docker run -i -v $DIR/echoconfig.yaml:/etc/bento.yaml:ro --rm $1 \
    -c /etc/bento.yaml | grep 'test123'
