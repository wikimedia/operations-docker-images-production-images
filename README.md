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

Creating an image
-----------------
Best practices for a service image depend on the language -- specifically, on the build.

### Go

We use vendoring, rather than Debian dependencies, to manage Go libraries. (That means the
image-build process is hermetic, with no downloads from GitHub; we can version the dependencies and
manage upgrades ourselves; and all the other usual advantages of vendoring. The downside is a
bulkier repo, but disk is cheap.) If the upstream repo doesn't include a vendor directory, you'll
need to manage it yourself.

Clone the upstream repository into a new repo on gitlab.wikimedia.org, then clone the Gitlab repo on
your laptop. Check out the commit you want to deploy (at a version tag, for instance) and then start
a new branch called "wikimedia" at that commit. Now run `go mod vendor` to automatically create a
vendor/ directory with all the dependencies. Commit the result into the wikimedia branch, and tag
it; if the original tag was "1.2.3" you might call yours "1.2.3-wikimedia".

If the upstream repo *does* include a vendor directory, and you don't need to make any other changes
to the code, you could skip GitLab -- below, when we refer to cloning the GitLab repo, you can
instead clone the upstream. But consider that this could stop working unexpectedly if the upstream
repo moves or disappears.

Here the production-images repo, start a new directory. (Copy and modify another image as a model.)
You need three files:

Use `docker-pkg update` as described below to update `changelog`. `* Initial release` is sufficient.

In `control`, along with the `Package`/`Description`/`Maintainer` headers found in all images, add a
header like `Build-Depends: golang1.21`, using whatever version of Go is needed for the software to
build.

In `Dockerfile.template`, outline a two-stage build. The first stage (FROM the same golang1.XX
image) clones your GitLab repo and runs `go build`; the second stage copies out the resulting
binary and runs it. Use whatever build flags are provided upstream, adding `-mod vendor` if it isn't
present. For example:

    FROM {{ "golang1.21" | image_tag }} as build
    USER nobody
    RUN mkdir -p /go/<PACKAGEPATH> \
      && cd /go/<PACKAGEPATH> \
      && git clone https://gitlab.wikimedia.org/<URL>.git \
      && cd <WORKDIR> \
      && git checkout tags/<VERSION> \
      && go build <FLAGS> -mod vendor \
      && cp <BINARY> /go/bin

    FROM {{ "bookworm" | image_tag }}
    COPY --from=build /go/bin/<BINARY> /usr/bin/
    USER {{ "nobody" | uid }}
    ENTRYPOINT ["/usr/bin/<BINARY>"]
    CMD <ARGS>

Updating an image
-----------------

Before building, make changes to the desired template in `./images` or `./istio` and update
the changelog using `docker-pkg`:

    $ docker-pkg -c <config-file> update <name> --version <version> --reason '* <to be added to changelog>' ./images/<name>

For example (images directory), note how we specify only images/ as the dir, and `kserve/build` becomes `kserve-build`:

    $ docker-pkg -c config.yaml update kserve-build --version 0.13.0 --reason '* Version bump.' ./images

The reason for not using ./images/kserve is that using that path, docker-pkg would be unable to see the golang dependency.

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
