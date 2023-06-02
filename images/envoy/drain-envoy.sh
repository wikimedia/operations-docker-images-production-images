#!/bin/bash
ADMIN_PORT=${ADMIN_PORT:=9901}
exec 4<>/dev/tcp/localhost/${ADMIN_PORT}
echo -e "POST /drain_listeners?graceful HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n" >&4
grep -q "OK" <&4 || exit 1
