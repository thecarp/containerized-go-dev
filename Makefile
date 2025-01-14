all: bin/example
test: lint unit-test

PLATFORM=local
UTIL_TAG=1.16.5-alpine

export DOCKER_BUILDKIT=1

.PHONY: bin/example
bin/example:
	@docker build . --target bin \
	--output bin/ \
	--platform ${PLATFORM}

.PHONY: unit-test
unit-test:
	@docker build . --target unit-test

.PHONY: unit-test-coverage
unit-test-coverage:
	@docker build . --target unit-test-coverage \
	--output coverage/
	cat coverage/cover.out

.PHONY: lint
lint:
	@docker build . --target lint

.PHONY: tidy
tidy:
	export DOCKER_BUILDKIT=1
	@docker build . --target tidy --output .

.PHONY: init
init:
	export DOCKER_BUILDKIT=1
	@docker build . --target mod-init --output .
