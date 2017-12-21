== Envoy TLS local proxy

This image allows to create a simple TLS termination sidecar for your service.

It expects:
- The private key to be injected at `/etc/envoy/ssl/service.key`
- The public cert to be injected at `/etc/envoy/ssl/service.crt`
- the SERVICE_NAME env variable to be defined
- the PUBLIC_PORT env variable to be defined - this will mark what port envoy
  would listen on.
- the SERVICE_PORT env variable - marking the port on which the upstream
  service is listening.

also needs, per the parent image:

- the SERVICE_ZONE env variable to define the service zone for envoy's
  zone-aware routing, which is unused in this image.


=== Quick start

You will need to mount a directory with your cert/key within the container in
order to provide the ssl certificates. The certificates should be owned by
uid 101, the "envoy" user id within the container.


    # Generate the ssl keypair
    $ mkdir ssl && pushd ssl
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout service.key -out service.crt
    # Change the owner of the certs to the envoy user.
    $ sudo chown 101:101 service.*
    $ popd
    # Now run the container
    $ docker run -e SERVICE_NAME=foo -e PUBLIC_PORT=9090 -e SERVICE_PORT=8080 \
        -e SERVICE_ZONE=foobar --mount type=bind,src=$PWD/ssl,dst=/etc/envoy/ssl,ro=true \
        docker-registry.wikimedia.org/envoy-tls-local-proxy:latest
