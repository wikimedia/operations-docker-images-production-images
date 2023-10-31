Wikimedia base docker images for production
===========================================

This repository includes:
 * the files necessary to build Wikimedia production base images
 * the files necessary to build non-Wikimedia service images
   based on Wikimedia base images intended for production use

Prerequisites
-------------
 * Docker
 * [docker-pkg](https://gerrit.wikimedia.org/r/admin/projects/operations/docker-images/docker-pkg)

Updating an image
-----------------

Before building, make changes to the desired template in `./images` or `./istio` and update
the changelog using `docker-pkg`:

    $ docker-pkg -c <config-file> update <name> --version <version> --reason '* <to be added to changelog>' ./images/<name>

For example (images directory):

    $ docker-pkg -c config.yaml update golang --version 1.14-1 --reason '* Version bump.' ./images/golang

For example (istio directory):

    $ docker-pkg -c config-istio.yaml update build --version 1.6.3 --reason '* Version bump.' ./istio/build

Build the images
----------------

The contents of the `./images`, `cert-manager` and `./istio` directories can be built using `docker-pkg` as follows:

   $ docker-pkg -c <config-file> build <directory>

If your configuration includes the login credentials for docker, the generated
images will be automatically pushed to the registry.

Weekly rebuild
--------------

Images are rebuilt weekly making use of the weekly-update.sh script
