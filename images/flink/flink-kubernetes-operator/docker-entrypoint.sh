#!/bin/bash

# Taken and modified from upstream apache/flink-kubernetes-operator:
# https://github.com/apache/flink-kubernetes-operator/blob/main/docker-entrypoint.sh

# FLINK_KUBERNETES_OPERATOR_HOME should have directories:
# - lib/     - with all required flink-kubernetes-operator jar depenendencies
# - webhook/ - with any flink-kubernetes-webhook jar dependencies
: ${FLINK_KUBERNETES_OPERATOR_HOME:=/opt/flink-kubernetes-operator}

# Constructs a Java CLASSPATH of all .jar files in a directory.
# Usage: CLASSPATH=$(constructClassPath /path/to/dir/with/jars)
constructClassPath() {
    jar_directory="${1}"
    while read -d '' -r jarfile ; do
        if [[ "${_classpath}" == "" ]]; then
            _classpath="${jarfile}";
        else
            _classpath="${_classpath}":"${jarfile}"
        fi
    done < <(find "${jar_directory}" ! -type d -name '*.jar' -print0 | sort -z)
    echo "${_classpath}"
    unset _classpath
}

usage="Usage: $(basename "$0") operator
    Or $(basename "$0") help

"

# Both operator and webhook use jars from the lib/ directory.
FLINK_KUBERNETES_OPERATOR_CLASSPATH=$(constructClassPath ${FLINK_KUBERNETES_OPERATOR_HOME}/lib)

if [ "$1" = "help" ]; then
    echo "${usage}"
    exit 0
elif [ "$1" = "operator" ]; then
    echo "Starting Operator"
    set -ex
    exec java \
        -cp "${FLINK_KUBERNETES_OPERATOR_CLASSPATH}" \
        $LOG_CONFIG \
        $JVM_ARGS \
        org.apache.flink.kubernetes.operator.FlinkOperator
elif [ "$1" = "webhook" ]; then
    echo "Starting Webhook"
    # Add any webhook specific jars to the classpath too.
    FLINK_KUBERNETES_WEBHOOK_CLASSPATH=$(constructClassPath "${FLINK_KUBERNETES_OPERATOR_HOME}/webhook")
    set -ex
    exec java \
        -cp "${FLINK_KUBERNETES_OPERATOR_CLASSPATH}:${FLINK_KUBERNETES_WEBHOOK_CLASSPATH}" \
        $LOG_CONFIG \
        $JVM_ARGS \
        org.apache.flink.kubernetes.operator.admission.FlinkOperatorWebhook
else
    echo "Invalid command '${1}'."
    echo "${usage}"
    exit 1
fi
