#!/bin/bash

set -eu

/usr/bin/pip3 wheel -r /deploy/frozen-requirements.txt -w /wheels

if [[ -e "/deploy/src/setup.py" ]]; then
    (cp -ax /deploy /tmp/ && cd /tmp/deploy/src && python3 setup.py bdist_wheel)
    mv /tmp/deploy/src/dist/*.whl /wheels/
else
    echo "No src/setup.py found, building a dependency-only package"
fi

(cd /wheels && tar -czvf artifacts.tar.gz ./*.whl)
