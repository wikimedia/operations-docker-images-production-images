#!/bin/bash

if [ -z ${RUNTIME_ROOT+x} ]; then
  echo "env RUNTIME_ROOT must be set to the path to runtime data directory." \
    "See ratelimit settings: https://github.com/envoyproxy/ratelimit/blob/master/src/settings/settings.go"
  exit 1
fi

if [ -z ${RUNTIME_SUBDIRECTORY+x} ]; then
  echo "env RUNTIME_SUBDIRECTORY must be set to the of the runtime ratelimit data subdirectory. " \
    "See ratelimit settings: https://github.com/envoyproxy/ratelimit/blob/master/src/settings/settings.go"
  exit 1
fi

/usr/bin/ratelimit_config_check \
  --config_dir "${RUNTIME_ROOT}/${RUNTIME_SUBDIRECTORY}" && \
exec /usr/bin/ratelimit