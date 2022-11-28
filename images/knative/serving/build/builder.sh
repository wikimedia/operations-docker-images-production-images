#!/bin/bash
#
# The knative serving and net-istio repositories don't provide a makefile, but
# they rely on Google's ko to build and push docker images to a repository.
# This script represents a quick way to avoid all boilderplate commands needed
# to just go-build some binaries.
#
set -ex

usage() {
    echo "Usage: $0 <knative-base-repo-full-path> <serving-repo-name>"
    exit 1
}

if [ $# -ne 2 ]; then
    usage
fi

# knative serving binaries
for target in activator autoscaler controller webhook queue domain-mapping domain-mapping-webhook
do
    pushd $1/$2/cmd/$target
    go build
    popd
done
