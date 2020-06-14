.PHONY: container_build container_shell build server clean distclean client github_client github_server

DOCKER_IMAGE=tribesthatmaybe/modpack
VERSION=$(shell cat version)
ARTIFACTS=$(shell pwd)/artifacts
ifndef VIRTUAL_ENV
CIENV = $(shell pwd)/.venv/bin/
else
CIENV = $(VIRTUAL_ENV)/bin/
endif

container_build:
	docker build \
		--label VERSION=$(VERSION) \
		--tag $(DOCKER_IMAGE):$(VERSION) \
		.
container_shell: container_build
	docker run \
		-it --rm \
		-v "$(shell pwd):/mnt" \
		$(DOCKER_IMAGE):$(VERSION) \
		shell

client: container_build
	docker run \
		--rm \
		-v "$(shell pwd):/mnt" \
		$(DOCKER_IMAGE):$(VERSION) \
		build
	mkdir -p artifacts
	cp build/release/ttmb-$(VERSION).zip $(ARTIFACTS)/ttmb-$(VERSION).zip

server: container_build
	rm -f build/server/mods/* $(ARTIFACTS)/ttmb-server-$(VERSION).zip
	docker run \
		--rm \
		-v "$(shell pwd):/mnt" \
		$(DOCKER_IMAGE):$(VERSION) \
		server
	mkdir -p artifacts
	cd build/server && zip -r $(ARTIFACTS)/ttmb-server-$(VERSION).zip *

build: client server

clean:
	rm -rf build/server build/release

distclean: clean
	rm -rf build curseforge.db packmaker.lock config.yml

github_client: client
	mkdir -p artifacts/github/client
	cd $(ARTIFACTS)/github/client && unzip $(ARTIFACTS)/ttmb-$(VERSION).zip

github_server: server
	mkdir -p artifacts/github/server
	cd $(ARTIFACTS)/github/server && unzip $(ARTIFACTS)/ttmb-server-$(VERSION).zip

env:
	test -z $(VIRTUAL_ENV) && (test -d .venv || ( mkdir .venv && pip install virtualenv==$(PY_VENV_VER) && virtualenv .venv)) || true
	test -d artifacts || ( mkdir artifacts ) || true
	test -z $(VIRTUAL_ENV) && (.venv/bin/pip install -r requirements.txt --upgrade) || \
		( pip install -r requirements.txt)

loregen: env
