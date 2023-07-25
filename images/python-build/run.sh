#!/bin/bash

PYTHON_SUFFIX=${PYTHON_SUFFIX:-3}
PIP=/usr/bin/pip"$PYTHON_SUFFIX"
PYTHON=python"$PYTHON_SUFFIX"

set -eu

echo "Creating wheels (without transitive dependencies)"
$PIP wheel --no-deps -r /deploy/frozen-requirements.txt -w /wheels

echo "Verifying generated wheels fullfil frozen requirements"
verif_dir=$(mktemp -d --tmpdir python-build-verif.XXXX)
trap 'rm -R "$verif_dir"' EXIT
mkdir -p "$verif_dir"

# --isolated prevents environment variables such as PIP_FIND_LINKS which would
# override let pip discover extra wheels beside the one we build.
# --no-index prevents looking up in the package index and instead pip can only
# search the wheels we have built via --find-links /wheels
#
# If a dependency is missing somehow, the build will fail indicating
# frozen-requirements.txt misses an entry.
$PIP wheel \
	--quiet --isolated \
	--no-index \
	--find-links /wheels \
	-r /deploy/frozen-requirements.txt \
	-w "$verif_dir"

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
