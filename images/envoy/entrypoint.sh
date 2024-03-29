#!/bin/bash
set -e
# If no envoy config files exist, create one based on the template and env variables injected
if [ ! -e /etc/envoy/envoy.yaml ]; then
    cd /etc && envsubst < /etc/envoy/envoy.yaml.tpl > /etc/envoy/envoy.yaml
fi
DRAIN_TIME_S=${DRAIN_TIME_S:=600}
DRAIN_STRATEGY=${DRAIN_STRATEGY:="gradual"}
SERVICE_NODE=${SERVICE_NODE:=$HOSTNAME}
if [ -n "${CONCURRENCY}" ]; then
    CONCURRENCY_CLI_SWITCH="--concurrency ${CONCURRENCY}"
else
    CONCURRENCY_CLI_SWITCH=""
fi

exec /usr/bin/envoy -c /etc/envoy/envoy.yaml \
    --service-node "$SERVICE_NODE" \
    --service-cluster "$SERVICE_NAME" \
    --service-zone "$SERVICE_ZONE" \
    --drain-time-s "$DRAIN_TIME_S" \
    --drain-strategy "$DRAIN_STRATEGY" \
    ${CONCURRENCY_CLI_SWITCH} \
    "$@"
