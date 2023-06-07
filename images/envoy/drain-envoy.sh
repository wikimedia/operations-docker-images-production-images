#!/bin/bash
ADMIN_PORT=${ADMIN_PORT:=9901}
CONN_FILTER=${CONN_FILTER:="http.ingress_https_${SERVICE_NAME}.downstream_cx_active"}
LOG_FD="/proc/1/fd/1"

# Trigger connection draining
echo "Draining connections" > ${LOG_FD}
exec 4<>/dev/tcp/localhost/${ADMIN_PORT}
echo -e "POST /drain_listeners?graceful HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n" >&4
grep -q "OK" <&4
if [ $? -ne 0 ]
then
    echo "Draining failed" > ${LOG_FD}
    exit 1
else
    echo "Draining started" > ${LOG_FD}
fi

# Wait until connections are closed and exit
# We do not handle a timeout in case of lingering connections. There can be two cases:
# - There are still connections at the end of envoy's drain-time-s, but we're under kubernetes
#   terminationGracePeriodSeconds, in which case envoy will close the connections itself
# - envoy's drain-time-s is set to longer than terminationGracePeriodSeconds, in which case the pod
#   will be SIGKILL'd by kubernetes after maximun terminationGracePeriodSeconds + 2s

CONN_ACTIVE=1
while [ ${CONN_ACTIVE} -ne 0 ]
do
    exec 4<>/dev/tcp/localhost/${ADMIN_PORT}
    echo -e "GET /stats?filter=${CONN_FILTER}&usedonly HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n" >&4
    CONN_ACTIVE=$(grep "${CONN_FILTER}" <&4 | cut -d":" -f2)
    echo "${CONN_ACTIVE} connections left" > ${LOG_FD}
    sleep 1
done
