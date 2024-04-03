== Pytorch images ==

=== Why do we build Pytorch images? ===

The goal is to create a base image already equipped with Pytorch and ROCm
libraries, to share it as a common layer more easily. The size of the ROCm
Pytorch version is currently big, and this is a compromise that we decided
to take in https://phabricator.wikimedia.org/T360638.

The alternative way would be to just pip-install the Pytorch package in
every Docker image built with Blubber, ending up in various Docker images
with big layers (10GB+) that don't share anything. This in turn would cause
more load to the Docker Registry, since our Kubernetes workers would need
to pull the same data multiple times (consuming bandwidth etc..).

=== How we build Pytorch images ===

We want to be able to list the "torch" Python package (in requirements.txt files)
in Blubber configs that use this base image, relying on the fact that pip
will not install another Pytorch version if it already finds another one
under /opt/lib/python/site-packages.
This is handy for downstream users since they will not need to change their
requirements.txt only for this use case (avoiding torch etc..). It should also
preserve transitive dependencies when pip installing, for example if a package
requires torch etc..
There are some nuances when working with
pip, namely that the following can happen:
1) "torch" (CPU vanilla version) is listed in a requirements.txt file in one
   of the Blubber configs.
2) pip downloads the package and its dependencies (a lot of Nvidia stuff for
   example) and then it realizes that a torch package is already deployed.
   Instead of simply stopping, it proceeds installing the other dependencies,
   and this may cause the final size of the image to increase of several GBs.

This approach wasn't tested with poetry, so the compatibility with it should
be checked before using something different than pip.

High level steps that need to be taken in the Pytorch base image:
1) Configure the image to install the Pytorch dependency as Blubber would do.
   Blubber is configured to install Python deps and wheels under /opt/lib/python,
   see https://github.com/wikimedia/blubber/blob/main/config/python.go
   Since Blubber uses the user "somebody" with fixed UID:GID, we need to create
   it to avoid any issues with (downstream) Blubber configs using this as base image.
   The command is the same that Blubber adds to every image, and in the future
   we may want to avoid this code duplication (for example, we could work with
   Releng to have a base Debian image that adds "somebody" with the right UID:GID
   and share it).
2) Install pytorch to a directory that will not be "copied" to multiple
   layers. If we pip-install torch to /opt/lib/python/site-packages, as
   Blubber does, we'll create a ~10GB Docker layer due to the RUN command
   executed. Then in downstream Blubber configs, we'll import this layer
   as part of the Pytorch base image, and we'll likely issue some COPY
   commands, for example, to move pip-installed/configured packages from
   the build image to the production/final one. This step will create another
   image layer, that will add another ~10GB to the final image size.
   The trick that we use here is to pip-install torch to /opt/lib/python/base-packages,
   a directory that Blubber doesn't consider/configure/care, adding a symbolic
   link to /opt/lib/python/site-packages/torch (and dependent packages).
   In this way the big torch directory shouldn't be present in multiple layers.
