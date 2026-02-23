#!/bin/bash
ADMIN_PORT=${ADMIN_PORT:=9901}
CONN_FILTER=${CONN_FILTER:="http.ingress_https_${SERVICE_NAME}.downstream_cx_active"}
LOG_FD="/proc/1/fd/1"

ADMIN_QUERY_PARAMS=""
if [ "${DRAIN_STRATEGY}" = "gradual" ]
then
    ADMIN_QUERY_PARAMS="${ADMIN_QUERY_PARAMS}${QUERY_PARAM_SEPARATOR:-?}graceful"
    QUERY_PARAM_SEPARATOR="&"
fi
if [ "${DRAIN_INBOUND_ONLY:-false}" = "true" ]
then
    ADMIN_QUERY_PARAMS="${ADMIN_QUERY_PARAMS}${QUERY_PARAM_SEPARATOR:-?}inboundonly"
    QUERY_PARAM_SEPARATOR="&"
fi

# Trigger connection draining
echo "Draining connections with params: '${ADMIN_QUERY_PARAMS}'" > ${LOG_FD}
exec 4<>/dev/tcp/localhost/${ADMIN_PORT}
echo -e "POST /drain_listeners${ADMIN_QUERY_PARAMS} HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n" >&4
grep -q "OK" <&4
if [ $? -ne 0 ]
then
    echo "Draining failed" > ${LOG_FD}
    exit 1
else
    echo "Draining started" > ${LOG_FD}
fi

# Wait until connections are closed, and an optional minimum wait time has passed, and exit.
# We do not handle a timeout in case of lingering connections. There can be two cases:
# - There are still connections at the end of envoy's drain-time-s, but we're under kubernetes
#   terminationGracePeriodSeconds, in which case envoy will close the connections itself
# - envoy's drain-time-s is set to longer than terminationGracePeriodSeconds, in which case the pod
#   will be SIGKILL'd by kubernetes after maximun terminationGracePeriodSeconds + 2s

WAIT_START_TIME=$(date +%s)

CONN_ACTIVE=1
while [ ${CONN_ACTIVE} -ne 0 ]
do
    exec 4<>/dev/tcp/localhost/${ADMIN_PORT}
    echo -e "GET /stats?filter=${CONN_FILTER}&usedonly HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n" >&4
    CONN_ACTIVE=$(grep "${CONN_FILTER}" <&4 | cut -d":" -f2)
    echo "${CONN_ACTIVE} connections left" > ${LOG_FD}
    sleep 1
done

# If a minimum wait time was specified, and the connection drain wait above did not take at least
# that long, wait for the remainder. This is relevant in contexts where this script is used as a
# preStop hook, and must prevent early termination of envoy (i.e., while service mesh listeners
# must remain available).

if [ -z "${DRAIN_WAIT_MINIMUM_S}" ]
then
    exit
elif ! printf "%d" "${DRAIN_WAIT_MINIMUM_S}" >/dev/null 2>&1
then
    echo "Invalid DRAIN_WAIT_MINIMUM_S '${DRAIN_WAIT_MINIMUM_S}' (expected integer) - exiting immediately" > ${LOG_FD}
    exit 1
fi

WAIT_END_TIME=$(date +%s)
WAIT_TOTAL_S=$((WAIT_END_TIME-WAIT_START_TIME))
if [ ${WAIT_TOTAL_S} -lt ${DRAIN_WAIT_MINIMUM_S} ]
then
    REMAINDER_S=$((DRAIN_WAIT_MINIMUM_S-WAIT_TOTAL_S))
    echo "Waiting an additional ${REMAINDER_S}s after connection drain" > ${LOG_FD}
    sleep ${REMAINDER_S}
fi
