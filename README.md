# devops-docker-tooling

A small, dependency-free container image for a static site, built as a
reference for Dockerfile hygiene: a pinned base, a multi-stage build that
templates the page with build metadata, an unprivileged runtime user, an
explicit healthcheck, and a plain compose file that ties it together. No
build tooling required to read it — `docker build` / `docker compose up`
are the only runtime dependencies.

## What's inside

```
Dockerfile           # two stages: templates content, then serves it as nginx
scripts/render.sh    # envsubst templating (sed fallback for local preview)
nginx.conf           # listens on 8080, tightly scoped static server
content/             # demo static site (index.html + healthz endpoint)
docker-compose.yml   # one service: build args, port, healthcheck, restart
.dockerignore        # excludes git + working files from the build context
```

## Usage

```bash
docker compose up --build -d
curl -s http://localhost:8080/          # static site
curl -s http://localhost:8080/healthz   # liveness probe -> 200 OK
docker compose down
```

Building a versioned image — the build stage stamps the landing page with
`BUILD_VERSION` / `BUILD_DATE` via `envsubst` (shipped with the nginx:alpine
base; no extra packages in the build):

```bash
BUILD_VERSION=v1.2.0 docker compose build
# or directly:
docker build --build-arg BUILD_VERSION=v1.2.0 --build-arg BUILD_DATE=2026-08-10 \
  -t docker-tooling-site:v1.2.0 .
```

No Docker handy? `scripts/render.sh` renders the same template locally —
it falls back to a plain `sed` substitution when `envsubst` is missing:

```bash
BUILD_VERSION=v1.2.0 ./scripts/render.sh > /tmp/index.html
```

## Design notes

- **Pinned base image** — `nginx:1.27-alpine`, never `latest`.
- **Multi-stage build** — a short-lived build stage renders the landing
  page template with build metadata; only the finished content crosses
  into the runtime stage. The runtime image stays a plain static server.
- **Non-root runtime** — the worker runs as the `nginx` user; the image
  does not need a privileged container.
- **Healthcheck built in** — the image declares a `HEALTHCHECK` using
  `wget` against `/healthz`, so `docker run` / compose get liveness for free.
- **Small context** — `.dockerignore` keeps local working files and the
  git metadata out of the build.

## Validation

```bash
make validate                                # hadolint + template render
hadolint Dockerfile                          # image-lint (run locally)
docker compose config                        # syntax-check the compose file
```

This repo is validation-light on purpose: none of these steps need a build
or a cluster.