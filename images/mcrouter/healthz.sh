#!/bin/bash
# Health check script for mcrouter - with no dependency besides bash.
set -e

# Open a socket to localhost
exec 3<>/dev/tcp/127.0.0.1/$PORT
echo "get __mcrouter__.config_md5_digest" >&3
echo "quit" >&3
MD5=$(cat <&3 | grep -v ^VALUE - | grep -v ^END - | tr -d \\r )
# TODO: support configuration as a string?
if [[ $CONFIG != file:* ]]; then
    echo "Checking string configuration not supported"
    exit 0
fi
echo -e "$MD5 /etc/mcrouter/config.json" > /tmp/configcheck
md5sum --quiet -c /tmp/configcheck
