SHELL := /bin/sh

.PHONY: build up down logs lint validate

build:
	docker build -t docker-tooling-site .

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f

# Local validation without a running daemon
lint:
	hadolint Dockerfile

validate: lint
	docker compose config --quiet