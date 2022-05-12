#!/bin/bash

exec /usr/local/sbin/rootlesskit /usr/local/sbin/buildkitd \
  --rootless \
  --oci-worker true \
  --oci-worker-gc \
  --oci-worker-rootless \
  --oci-worker-no-process-sandbox \
  --containerd-worker false \
  "$@"
