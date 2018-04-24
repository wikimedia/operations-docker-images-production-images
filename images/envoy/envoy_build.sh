#!/bin/bash
set -e
# This is mostly extracted from envoy's own build system, just organized in a single script
# to adapt to our build process.

export DEBIAN_FRONTEND=noninteractive
# Envoy build within a container image build process.
# This is aimed at reducing to the bare minimum the amount of indirection.
apt-get update
apt-get install -y --no-install-recommends ca-certificates git gnupg2
(git clone https://github.com/envoyproxy/envoy.git /source && cd source \
     && git checkout v1.6.0)
apt-get install --no-install-recommends -y wget software-properties-common make cmake python python-pip \
        bc libtool automake zip time golang g++ gdb strace patch rsync

mkdir /build
# Copy files where we expect them to be
(cd /source/ci/build_container && \
     cp ./build_and_install_deps.sh ./recipe_wrapper.sh ./Makefile /  &&\
     mkdir /bazel-prebuilt && cp /source/WORKSPACE /bazel-prebuilt/ && \
     cp -ax /source/bazel /bazel-prebuilt && \
     mkdir /build_recipes && cp ./build_recipes/*.sh /build_recipes/ )


# Install clang
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
echo 'deb http://apt.llvm.org/stretch/ llvm-toolchain-stretch-5.0 main' > /etc/apt/sources.list.d/llvm.list
apt-get update && apt-get install -y clang-5.0 clang-format-5.0
# Bazel and related dependencies.
apt-get install --no-install-recommends -y openjdk-8-jdk-headless curl
echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list
curl https://bazel.build/bazel-release.pub.gpg | apt-key add -
apt-get update
apt-get install -y bazel
rm -rf /var/lib/apt/lists/*

# virtualenv
pip install virtualenv

# buildifier
export GOPATH=/usr/lib/go
go get github.com/bazelbuild/buildifier/buildifier

# GCC for everything.
export CC=gcc
export CXX=g++
export THIRDPARTY_DEPS=/tmp
export THIRDPARTY_SRC=/thirdparty
DEPS=$(python <(cat /bazel-prebuilt/bazel/target_recipes.bzl; \
                echo "print ' '.join(\"${THIRDPARTY_DEPS}/%s.dep\" % r for r in set(TARGET_RECIPES.values()))"))
# TODO(htuch): We build twice as a workaround for https://github.com/google/protobuf/issues/3322.
# Fix this. This will be gone real soon now.
export THIRDPARTY_BUILD=/thirdparty_build
export CPPFLAGS="-DNDEBUG"
echo "Building opt deps ${DEPS}"
/build_and_install_deps.sh ${DEPS}

echo "Building Bazel-managed deps (//bazel/external:all_external)"
mkdir /bazel-prebuilt-root /bazel-prebuilt-output
BAZEL_OPTIONS="--output_user_root=/bazel-prebuilt-root --output_base=/bazel-prebuilt-output"
cd /bazel-prebuilt
for BAZEL_MODE in opt dbg fastbuild; do
    bazel ${BAZEL_OPTIONS} build -c "${BAZEL_MODE}" //bazel/external:all_external
done
# Allow access by non-root for building.
chmod -R a+rX /bazel-prebuilt-root /bazel-prebuilt-output
cd /source
test -z "${http_proxy}" || git config --global http.proxy "$http_proxy"

./ci/do_ci.sh bazel.release.server_only

# Now let's extract the envoy binary from the build, and cleanup the build workspace
mv /build/envoy/source/exe/envoy /build/envoy.binary && rm -rf /build/envoy
