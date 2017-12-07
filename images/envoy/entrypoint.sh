#!/bin/bash
cd /etc && envsubst < /etc/envoy.yaml.tpl > /etc/envoy.yaml
/usr/bin/envoy -c /etc/envoy.yaml --service-cluster "$SERVICE_NAME" --v2-config-only
