#!/bin/bash
set -e

# Source the env variables
. /etc/apache2/envvars

# Using exec here so that signals from docker are handled properly.
exec /usr/sbin/apache2 -d /etc/apache2 -DFOREGROUND -k start "$@"
