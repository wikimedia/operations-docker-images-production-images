python-build images
===================

These base images include the python version provided by the
corresponding Debian distribution. They are used to build wheels
matching the deployment targets' operating systems.

The container expects a deployment git repository to be bind mounted on
`/deploy`. The repository should have:
* `/frozen-requirements.txt` containing the list of pinned dependencies
* `/src` directory holding the application source code, typically a git
  submodule to the source repository.

The container builds the wheels which are written to the `/wheels` directory
and upon completions creates an archive of all the wheels as
`/wheels/artifacts.tar.gz`.

Usage
-----

Given a deployment repository having:
```
.
├── frozen-requirements.txt
└── wheels/artifacts.tar.gz
```

One can build the wheels with:
```
mkdir wheels
docker run docker-registry.wikimedia.org/python3-build-buster -rm \
    --user=$UID \
    -v /etc/group:/etc/group:ro \
    -v /etc/passwd:/etc/passwd:ro \
    -v .:/deploy:ro \
    -v ./wheels:/wheels
```
It is recommended to delete all existing wheels before building new ones. Else
you might end up with duplicate wheels if the `frozen-requirements.txt` does
not pin versions explicitly or extra wheels if they have meanwhile been removed
from the list of requirements.

When the deploy repository has the source repository as a submodule in `./src`,
python-build images will create a wheel for the source code by running `pip bdist_wheel`.

Live usage example
------------------

https://gerrit.wikimedia.org/g/operations/docker-images/docker-pkg/deploy/+/HEAD
