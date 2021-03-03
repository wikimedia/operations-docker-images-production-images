#!/bin/bash
set -e
MEMC_ARGS=""

case $MEMC_MODE in
    "tls")
    # tls only, public interface
    MEMC_ARGS="-l 0.0.0.0 -p $MEMC_PORT"
    MEMC_ARGS="$MEMC_ARGS -Z -o ssl_chain_cert=/etc/memcached/ssl/chained-cert.pem -o ssl_key=/etc/memcached/ssl/key.pem"
    ;;
    "local")
    # plaintex, localhost only.
    MEMC_ARGS="-l 127.0.0.1 -p $MEMC_PORT"
    ;;
    "insecure")
    # plaintext, public
    MEMC_ARGS="-l 0.0.0.0 -p $MEMC_PORT"
    ;;
    "dual")
    # tls public, with a local non-tls interface
    CLEARTEXT_PORT=$(( $MEMC_PORT + 1 ))
    MEMC_ARGS="-l 0.0.0.0 -p $MEMC_PORT -l notls:127.0.0.1:${CLEARTEXT_PORT}"
    MEMC_ARGS="$MEMC_ARGS -Z -o ssl_chain_cert=/etc/memcached/ssl/chained-cert.pem -o ssl_key=/etc/memcached/ssl/key.pem"
    ;;
    *)
    echo "Unsupported mode $MEMC_MODE"
    exit 1
    ;;
esac

MEMC_ARGS="$MEMC_ARGS -m $MEMC_MEMORY -c $MEMC_CONN_LIMIT -f $MEMC_GROWTH_FACTOR -n $MEMC_MIN_SLAB_SIZE"
exec /usr/bin/memcached $MEMC_ARGS $MEMC_ADDITIONAL_ARGS