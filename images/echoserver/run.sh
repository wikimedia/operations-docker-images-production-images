#!/bin/sh

# Copyright 2018 The Kubernetes Authors.
# Copyright 2021 Wikimedia Foundation, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ ! -e /certs/tls.key -o ! -e /certs/tls.crt ]; then
    echo "Generating self-signed cert"
    mkdir -p /certs
    openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
    -keyout /certs/tls.key \
    -out /certs/tls.crt \
    -subj "/C=UK/ST=Warwickshire/L=Leamington/O=OrgName/OU=IT Department/CN=example.com"
fi

echo "Starting nginx"
nginx -g "daemon off;"
