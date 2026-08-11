SHELL := /bin/sh

BUILD_VERSION ?= dev
BUILD_DATE ?= $(shell date -u +%Y-%m-%d)

.PHONY: build build-release up down logs lint check-pins validate render

build:
	docker build -t docker-tooling-site .

build-release:
	docker build --build-arg BUILD_VERSION=$(BUILD_VERSION) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t docker-tooling-site:$(BUILD_VERSION) .

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f

# Render the landing page template without a Docker daemon (see scripts/render.sh)
render:
	BUILD_VERSION=$(BUILD_VERSION) BUILD_DATE=$(BUILD_DATE) scripts/render.sh

# Local validation without a running daemon
lint:
	hadolint Dockerfile

check-pins:
	scripts/check-pins.sh

validate: lint check-pins render
	docker compose config --quiet