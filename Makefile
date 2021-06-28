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
	@docker run -t -i -v `pwd`:/src --workdir /src --rm golang:${UTIL_TAG} /usr/local/go/bin/go mod tidy

.PHONY: init
init:
	@docker run -t -i -v `pwd`:/src --workdir /src --rm golang:${UTIL_TAG} /usr/local/go/bin/go mod init
