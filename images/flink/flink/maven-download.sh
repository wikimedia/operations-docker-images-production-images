#!/bin/bash

# Downloads .jar files, and their sha1 checksums and signatures, verifies them,
# and then moves them to a destination directory.
#
# Usage:
#   ./maven-download.sh <group_id> <artifact_id> <version> [dest_dir=./] [maven_mirror_base_uri=https://repo1.maven.org/maven2] [maven_keyserver=hkps://keyserver.ubuntu.com']
#
# Example:
# Download my-artifact-id-1.2.0.jar and install it into /my/dest/dir
#   ./maven-download.sh org.my.group.id my-artifact-id.jar 1.2.0 /my/dest/dir

group_id=$1
artifact_id=$2
version=$3
dest_dir=${4:-"$(pwd)"}
maven_mirror_base_uri=${5:-'https://repo1.maven.org/maven2'}
# PGP Keyserver for verifying signatures of .jars downloaded from maven
# Maven central uses keyserver.ubuntu.com.
maven_keyserver=${6:-'hkps://keyserver.ubuntu.com'}


artifact_filename="${artifact_id}-${version}.jar"
artifact_uri="${maven_mirror_base_uri}/$(echo ${group_id} | tr '.' '/')/${artifact_id}/${version}/${artifact_filename}"
checksum_uri="${artifact_uri}.sha1"
signature_uri="${artifact_uri}.asc"


set -ex

curl --remote-name-all "${artifact_uri}"
curl --remote-name-all "${checksum_uri}"
curl --remote-name-all "${signature_uri}"

# Conditionally set GPG_HTTP_PROXY_OPTION if $http_proxy is set.
# gpg needs this set in --keyserver-options if an http proxy needs
# to be used when retrieving keys.
GPG_HTTP_PROXY_OPTION=${http_proxy:+"http-proxy=${http_proxy}"}

# Verify checksum
# NOTE: jar.sha1 file is not in expected sha sum format; it only has the sum.
# Echo the expected format into file.
echo "$(cat ${artifact_filename}.sha1)  ${artifact_filename}" > "${artifact_filename}.sha1"
sha1sum --check -c "${artifact_filename}.sha1" --status
# Verify the signature
gpg --auto-key-locate keyserver --keyserver "${maven_keyserver}" --keyserver-options "auto-key-retrieve ${GPG_HTTP_PROXY_OPTION}" \
    --verify "${artifact_filename}.asc" "${artifact_filename}"

# mv artifact into dest_dir
mv -v "${artifact_filename}" "${dest_dir}/"


# NOTE: We could just use mvn dependency-plugin:copy to get the .jar,
#       but I did not find an automated way to verify checksum and signature, so
#       we'd have to manually curl those from the maven repo anyway.
#       If we do figure out how to do this with mvn, the download command is:
#
# mvn  org.apache.maven.plugins:maven-dependency-plugin:copy \
#     -Dartifact="${maven_coordinate}" \
#     -DoutputDirectory="${dest_dir}"
