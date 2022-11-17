#!/bin/bash

# A simple wrapper that executes all the args it is given.
#
# We don't need the full functionality of upstream's flink docker-entrypoint.sh script
# (https://github.com/apache/flink-docker/blob/master/1.16/scala_2.12-java11-ubuntu/docker-entrypoint.sh),
# as we expect this image to be used only by the flink-kubernetes-operator, which always runs
# in 'pass-through' mode anyway.  Upstream flink-docker's docker-entrypoint.sh is mostly a
# helper for running in regular docker / docker-compose.
#
# Since this script is basically useless, it would be nice to just get rid of it.
# However, upstream flink kubernetes code will consruct commands to run using
# the 'kubernetes.entry.path', which defaults to /docker-entrypoint.sh.
# It is easier to work with upstream defaults than to change them to make them
# work without a single entrypoint script.

# echo commands to the terminal output
set -ex

# Running command in pass-through mode to run a custom command in the container.
exec "${@}"
