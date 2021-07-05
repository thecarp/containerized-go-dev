# syntax = docker/dockerfile:1-experimental

FROM --platform=${BUILDPLATFORM} golang:1.16.5-alpine AS base
WORKDIR /src
ENV CGO_ENABLED=1
RUN apk update
RUN apk add gcc g++
RUN mkdir /out

FROM base AS buildbase
COPY go.* .
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

FROM buildbase AS build
ARG TARGETOS
ARG TARGETARCH
RUN --mount=target=. \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /out/example .

FROM base AS unit-test
RUN --mount=target=. \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go test -v -coverprofile=/out/cover.out ./...

FROM golangci/golangci-lint:v1.31.0-alpine AS lint-base

FROM base AS lint
RUN --mount=target=. \
    --mount=from=lint-base,src=/usr/bin/golangci-lint,target=/usr/bin/golangci-lint \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/.cache/golangci-lint \
    golangci-lint run --timeout 10m0s ./...

FROM base as mod-init-base
WORKDIR /out
COPY . .
ENV MODNAME example
RUN go mod init "${MODNAME}" && go mod tidy

FROM base AS mod-tidy
WORKDIR /out
COPY . .
RUN go mod tidy

FROM scratch AS mod-init
COPY --from=mod-init-base /out/go.mod /go.mod
COPY --from=mod-init-base /out/go.sum /go.sum

FROM scratch AS tidy
COPY --from=mod-tidy /out/go.mod /go.mod
COPY --from=mod-tidy /out/go.sum /go.sum

FROM scratch AS unit-test-coverage
COPY --from=unit-test /out/cover.out /cover.out

FROM scratch AS bin-unix
COPY --from=build /out/example /

FROM bin-unix AS bin-linux
FROM bin-unix AS bin-darwin

FROM scratch AS bin-windows
COPY --from=build /out/example /example.exe

FROM bin-${TARGETOS} as bin
