#!/bin/bash
SSL_DIR="/etc/mcrouter/ssl"
if [ "$USE_SSL" == "yes" ]; then
    SSL_ARGS="--ssl-port ${SSL_PORT} --pem-cert-path=${SSL_DIR}/cert.pem --pem-key-path=${SSL_DIR}/key.pem --pem-ca-path=${SSL_DIR}/ca.pem"
else
    SSL_ARGS=""
fi
exec /usr/bin/mcrouter --debug-fifo-root /var/lib/mcrouter/fifos --stats-root /var/lib/mcrouter/stats \
    -p $PORT --config "${CONFIG}" \
    --route-prefix=$ROUTE_PREFIX \
    --cross-region-timeout-ms=${CROSS_REGION_TO} \
    --cross-cluster-timeout-ms=${CROSS_CLUSTER_TO} \
    --send-invalid-route-to-default \
    --file-observer-poll-period-ms=1000 \
    --file-observer-sleep-before-update-ms=100 \
    --num-proxies=${NUM_PROXIES} \
    --probe-timeout-initial=${PROBE_TIMEOUT} \
    --timeouts-until-tko=${TIMEOUTS_UNTIL_TKO} ${SSL_ARGS}