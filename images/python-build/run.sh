#!/bin/bash

PYTHON_SUFFIX=${PYTHON_SUFFIX:-3}
PIP=/usr/bin/pip"$PYTHON_SUFFIX"
PYTHON=python"$PYTHON_SUFFIX"

set -eu

$PIP wheel -r /deploy/frozen-requirements.txt -w /wheels

if [[ -e "/deploy/src/setup.py" ]]; then
    cp -ax /deploy /tmp/
    (
    cd /tmp/deploy/src
    # Setting source files to commit date of HEAD
    SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct) \
        $PYTHON setup.py bdist_wheel
    )
    mv /tmp/deploy/src/dist/*.whl /wheels/
else
    echo "No src/setup.py found, building a dependency-only package"
fi

(cd /wheels && tar -czvf artifacts.tar.gz ./*.whl)
