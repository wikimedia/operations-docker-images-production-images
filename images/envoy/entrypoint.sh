#!/bin/bash
set -e
# Create the envoy config file from the env variables injected
cd /etc && envsubst < /etc/envoy/envoy.yaml.tpl > /etc/envoy/envoy.yaml
/usr/bin/envoy -c /etc/envoy/envoy.yaml --service-cluster "$SERVICE_NAME" --service-zone "$SERVICE_ZONE" --v2-config-only
