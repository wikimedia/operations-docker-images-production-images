#!/bin/bash
IMAGE_NAME=$1

docker run --rm \
    -e SERVICE_NAME=test \
    -e SERVICE_PORT=1234 \
    --entrypoint /bin/bash \
    $IMAGE_NAME \
    -c 'envsubst < /etc/envoy/envoy.yaml.tpl > /etc/envoy/envoy.yaml && /usr/bin/envoy -c /etc/envoy/envoy.yaml --mode validate'
