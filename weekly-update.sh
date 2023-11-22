#!/bin/bash
# Copyright (c) Wikimedia Foundation, 2023-
# This program is free software, see LICENSE for details

# TODO: check args
IMAGE_DIR=${1:-images}
CURDATE=$(date +%Y%m%d)
pushd "$IMAGE_DIR" || exit
while IFS= read -r -d '' changelog; do
    obj=$(dirname "$changelog")
    # Exclude spark images, they're too big to rebuild every week.
    if [[ "$obj" == *"spark"* ]]; then
        echo "skipping rebuild of $obj"
    fi
    cur_version=$(dpkg-parsechangelog -l "$changelog" --show-field Version)
    version=$(echo "$cur_version" | sed -E 's/\-[0-9]{8}$//')
    version="${version}-${CURDATE}"
    if [[ -n $version ]]; then
        DEBFULLNAME="Image build Bot" DEBEMAIL="root@wikimedia.org" dch -c "$changelog" -v "$version" --no-auto-nmu -D wikimedia --force-distribution "Weekly rebuild." 2>/dev/null
        git add "$changelog"
    else
        echo "Could not find a version for $obj"
    fi
done < <(find . -type f -name "changelog" -print0)
popd || exit
git commit -m "Weekly rebuild of $IMAGE_DIR - $CURDATE"
# you need push rights on the repository. Those should be granted to imageupdatebot
git push