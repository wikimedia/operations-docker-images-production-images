# Mcrouter image

This docker image allows running an mcrouter image.

It supports setting up listening to TLS.

## Running
Several environment variables can be set to control the command-line behaviour. Most importantly, setting `USE_SSL=yes` will have mcrouter listen on the port defined in `SSL_PORT` or not. See below for all the environment variables you can define.

| CLI option                   | Environment variable | Default value                  |
| ---------------------------- | -------------------- | ------------------------------ |
| `--route-prefix`             | `ROUTE_PREFIX`       | /default/cluster               |
| `--cross-region-timeout-ms`  | `CROSS_REGION_TO`    | 250                            |
| `--cross-cluster-timeout-ms` | `CROSS_CLUSTER_TO`   | 1000                           |
| `--num-proxies`              | `NUM_PROXIES`        | 1                              |
| `--probe-timeout-initial`    | `PROBE_TIMEOUT`      | 10000                          |
| `--timeouts-until-tko`       | `TIMEOUTS_UNTIL_TKO` | 5                              |
| `--config`                   | `CONFIG`             | file:/etc/mcrouter/config.json |

You will need to provide the following volumes:
* `/etc/mcrouter/config.json` with the full configuration for routes (or override the CONFIG env variable)
* If you want to extract stats and/or debug mcrouter, `/var/lib/mcrouter/{fifos,stats}`
* If you want to use TLS, `/etc/mcrouter/ssl` should be mounted, containing:
    * the private key at `key.pem`
    * the public cert at `cert.pem`
    * the CA cert at `ca.pem`

## Example

```
CONF='{"pools":{"A":{"servers":["127.0.0.1:5001"]}}, "route":"PoolRoute|A"}'
docker run --rm -p 5001:5001 -e CONFIG="$CONF" \
     docker-registry.wikimedia.org/mcrouter:latest
```