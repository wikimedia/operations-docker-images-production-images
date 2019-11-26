#!/bin/bash
set -e
# Set optional variables to defaults if nothing is declared.
ADMIN_LISTEN=${ADMIN_LISTEN:-127.0.0.1}
ADMIN_PORT=${ADMIN_PORT:-1667}
UPSTREAM_TIMEOUT=${UPSTREAM_TIMEOUT:-60.0s}
# Create the envoy config file from the env variables injected
envsubst < /etc/envoy/envoy.yaml.tpl > /etc/envoy/envoy.yaml
exec /usr/bin/envoy -c /etc/envoy/envoy.yaml --service-cluster "$SERVICE_NAME" --service-zone "$SERVICE_ZONE"
