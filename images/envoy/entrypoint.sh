#!/bin/bash
set -e
# If no envoy config files exist, create one based on the template and env variables injected
if [ ! -e /etc/envoy/envoy.yaml ]; then
    cd /etc && envsubst < /etc/envoy/envoy.yaml.tpl > /etc/envoy/envoy.yaml
fi
exec /usr/bin/envoy -c /etc/envoy/envoy.yaml --service-cluster "$SERVICE_NAME" --service-zone "$SERVICE_ZONE"
