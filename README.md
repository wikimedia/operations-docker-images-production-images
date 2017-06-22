Wikimedia base docker images for production
===========================================

This repository includes the files needed to build
the base docker images used for production Wikimedia services.

Overview
--------

The `build` script accepts one mandatory parameter, the directory to scan for
docker images:

  $ ./build <directory>

and will then scan that directory and its chidren for directories containing:

* A Dockerfile.template file
* A debian-formatted changelog

based on information in the changelog, on configuration options read from a
config file, and on what is found in the Dockerfile.template, a dockerfile is
generated and an image is built out of it.
Name and tag of this image will be defined by the last entry of the changelog.

Finally, if you configured a registry url, a username and password, each and
every one of these images will be pushed to the registry of your choice.


Installation
------------

The repository has a `deploy` branch with... wheels included.
Once you've cloned the repository you can just run

  $ git checkout deploy
  $ make install

This will create a virtual environment under `.venv`. To use the tool you just
need to activate it.

  $ . .venv/bin/activate
  $ ./build images


Build the images
----------------

This is as simple as launching the build script, indicating as a first argument
the directory to scan for dockerfiles.

The build script will search for Dockerfile.template files in the tree, and then
for a changelog, in debian format, describing the docker image, from the same
directory.

The name and tag of the image will be determined from the changelog file, so
it's fundamental you add your changelog entry there. For most containers, a
debian-like versioning is a good idea to keep into account the security updates
that might happen.

The templating system
---------------------

Instead of writing plain dockerfiles, we think using jinja2 templates gives us
an edge: there are a lot of common constructs that we don't want to replicate,
and they are exposed to the templates as variables and filters:

### Variables

* `registry`: the address of the docker registry
* `seed_image`: the seed image to use as a base for the production dockerfiles


### Filters

* `image_tag`: This filter allows to retrieve the current image tag for a
  specific image name. Thus this filter will search the current version of the `nodejs-dev` image and substitute it in the template. This allows to keep all dependencies updated automagically
  in sync. Example

``` dockerfile
FROM {{ registry }}/{{ "nodejs-dev" | image_tag }}
```

 * `apt_install`: this filter will get the string you pass it as a list of packages to install with apt, and add the correct stanza to your dockerfile.


Regenerate artifacts
--------------------

You can regenerate artifacts as follows, assuming you have docker installed:

    $ git checkout deploy
    $ git merge master # Update the deploy branch
    $ make .artifacts

if you don't have docker installed, add `DOCKER=0`  in the make invocation, but
remember the artifacts you'll generate will be platform-specific. Do NOT submit
to the deploy repo wheels built without docker.
