#!/bin/bash

# echo commands to the terminal output
set -ex

exec /usr/bin/tini -s -- /usr/bin/spark-operator "$@"
