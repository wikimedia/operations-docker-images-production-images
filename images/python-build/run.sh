#!/bin/bash
set -eu

/usr/bin/pip3 wheel -r /deploy/frozen-requirements.txt -w /wheels
(cp -ax /deploy /tmp/ && cd /tmp/deploy/src && python3 setup.py bdist_wheel)
mv /tmp/deploy/src/dist/*.whl /wheels/
(cd /wheels && tar -czvf artifacts.tar.gz ./*.whl)
