#!/bin/bash

set -eu -o pipefail

function usage {
    cat <<EOF
Usage: docker run ... this-image SUBCOMMAND [ options ... ]

SUBCOMMAND may be one of 'gc' or 'resource-monitor'.

Make sure you pass a bind mount for /var/run/docker.sock to the
container, otherwise nothing will work.

EOF
    exit 1
}

case "${1:-}" in
    "")
        usage
        ;;
    gc)
        shift
        prg=/docker-gc/docker-gc.py
        ;;
    resource-monitor)
        shift
        prg=/docker-gc/docker-resource-access-monitor.py
        ;;
    *)
        usage
        ;;
esac

exec "$prg" "$@"
    
