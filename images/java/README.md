### Upgrading and Rebuilding

Whenever you are releasing a new version of this image, be
sure to check the version of the openjdk package that is
being installed, and sync the image's version in the
changelog files with that version.

Context: In openjdk-11, we have started basing the image version
on the openjdk debian package version. We don't pin the
debian package version anywhere, so it is possible that
an image rebuild could cause a new version of Java to be
installed.
