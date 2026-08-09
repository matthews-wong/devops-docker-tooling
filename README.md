# devops-docker-tooling

A small, dependency-free container image for a static site, built as a
reference for Dockerfile hygiene: a pinned base, an unprivileged runtime
user, an explicit healthcheck, and a plain compose file that ties it
together. No build tooling required to read it — `docker build` / `docker
compose up` are the only runtime dependencies.

## What's inside

```
Dockerfile           # nginx:1.27-alpine, USER nginx, HEALTHCHECK
nginx.conf           # listens on 8080, tightly scoped static server
content/             # demo static site (index.html + healthz endpoint)
docker-compose.yml   # one service: build, port, healthcheck, restart
.dockerignore        # excludes git + working files from the build context
```

## Usage

```bash
docker compose up --build -d
curl -s http://localhost:8080/          # static site
curl -s http://localhost:8080/healthz   # liveness probe -> 200 OK
docker compose down
```

## Design notes

- **Pinned base image** — `nginx:1.27-alpine`, never `latest`.
- **Non-root runtime** — the worker runs as the `nginx` user; the image
  does not need a privileged container.
- **Healthcheck built in** — the image declares a `HEALTHCHECK` using
  `wget` against `/healthz`, so `docker run` / compose get liveness for free.
- **Small context** — `.dockerignore` keeps local working files and the
  git metadata out of the build.

## Validation

```bash
hadolint Dockerfile                        # image-lint (run locally)
docker compose config                       # syntax-check the compose file
```

This repo is validation-light on purpose: neither step needs a build or
a cluster.