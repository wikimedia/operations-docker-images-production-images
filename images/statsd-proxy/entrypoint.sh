#!/bin/bash
cd /etc && envsubst < /etc/statsd-proxy.cfg.tpl > /etc/statsd-proxy.cfg
/usr/sbin/statsd-proxy -f /etc/statsd-proxy.cfg
