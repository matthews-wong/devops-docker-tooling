SHELL := /bin/sh

# Override on a podman-only box: make build DOCKER=podman
DOCKER ?= docker
BUILD_VERSION ?= dev
BUILD_DATE ?= $(shell date -u +%Y-%m-%d)

.PHONY: build build-release up down logs lint check-pins test scan validate render

build:
	$(DOCKER) build -t docker-tooling-site .

build-release:
	$(DOCKER) build --build-arg BUILD_VERSION=$(BUILD_VERSION) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t docker-tooling-site:$(BUILD_VERSION) .

up:
	$(DOCKER) compose up -d --build

down:
	$(DOCKER) compose down

logs:
	$(DOCKER) compose logs -f

# Render the landing page template without a Docker daemon (see scripts/render.sh)
render:
	BUILD_VERSION=$(BUILD_VERSION) BUILD_DATE=$(BUILD_DATE) scripts/render.sh

# Local validation without a running daemon
lint:
	hadolint Dockerfile

check-pins:
	scripts/check-pins.sh

test:
	scripts/test-check-pins.sh

# Optional: trivy misconfig/CVE/SBOM scan (skips gracefully if trivy is absent)
scan:
	scripts/scan.sh

validate: lint check-pins test render
	$(DOCKER) compose config --quiet