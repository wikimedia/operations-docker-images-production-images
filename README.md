Wikimedia base docker images for production
===========================================

This repository includes the files needed to build
the base docker images used for production Wikimedia services.

Build the images
----------------

The contents of the images directory can be built using `docker-pkg` as follows:

   $ docker-pkg -c <config-file> images

if your configuration includes the login credentials for docker, the generated
images will  be pushed to the registry.
