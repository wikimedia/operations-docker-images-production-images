#!/bin/bash
IMAGE_NAME=$1

# Ensure the additional plugins (kubepods, kubeapi) have been build
test "$(docker run --rm \
    --entrypoint /usr/bin/coredns \
    $IMAGE_NAME \
    -plugins | grep kube)" ==  "kubeapi
kubepods
kubernetes"
