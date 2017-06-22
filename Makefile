DOCKER ?= 1

all: clean install

install: .venv .artifacts
	. .venv/bin/activate && pip install --use-wheel .artifacts/*.whl

# Dev virtualenv to generate frozen requirements
.venv-dev:
	virtualenv --python python3 .venv-dev
	. .venv-dev/bin/activate && pip install -r requirements.txt

frozen-requirements.txt: .venv-dev requirements.txt
	. .venv-dev/bin/activate && pip freeze | grep -v pkg-resources > frozen-requirements.txt


.venv:
	virtualenv --python python3 .venv
	. .venv/bin/activate && pip install --upgrade pip
	. .venv/bin/activate && pip install wheel

.artifacts: frozen-requirements.txt

ifeq ($(DOCKER), 1)
.artifacts: production-image.created
	docker run --rm -v $(CURDIR):/build:rw -v /etc/group:/etc/group:ro \
		 -v /etc/passwd:/etc/passwd:ro --user=$(UID) production-images-build:latest \
		/bin/sh -c 'cd /build && /virtualenv/bin/pip wheel -r frozen-requirements.txt -w .artifacts'
else
.artifacts: frozen-requirements.txt
	. .venv-dev/bin/activate && pip wheel -r frozen-requirements.txt -w $(CURDIR)/.artifacts
endif

production-image.created:
	docker build -t production-images-build:latest -f Dockerfile.build .
	touch production-image.created

clean-artifacts:
ifeq ($(DOCKER), 1)
	-docker rmi production-images-build:latest
	rm production-image.created
endif
	rm -rf .artifacts

clean: clean-artifacts clean-dev
	rm -rf .venv
	rm -rf frozen-requirements.txt

clean-dev:
	rm -rf .venv-dev

PHONY: clean clean-artifacts clean-dev install
