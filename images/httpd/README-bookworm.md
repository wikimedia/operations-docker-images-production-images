# Maintaining the "bookworm" track image

* If you are releasing changes to `Dockerfile.template`, please apply the
  same changes to `bookworm/Dockerfile.template` and bump `bookworm/changelog`.
* If you are making changes to image dependency files, no changes need to be
  mirrored to `bookworm/` (as they are symlinked there), but please still do
  bump `bookworm/changelog`.
