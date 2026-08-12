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
scripts/check-render.sh + neg-check-render.sh   # placeholder-drift gate + test
scripts/check-pins.sh + test-check-pins.sh   # digest-pin gate + smoke tests
scripts/test-nginx-conf.sh # asserts the server config invariants hold
scripts/scan.sh      # trivy misconfig/CVE/SBOM scan (optional tool)
nginx.conf           # listens on 8080, hardened static server (headers, caching)
content/             # demo static site (index.html + healthz endpoint)
docker-compose.yml   # one service: build args, loopback port, read-only runtime
docs/security.md     # CVE scan + SBOM workflow
docs/runtime-capsule.md  # podman vs docker cheat sheet
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

- **Digest-pinned base image** — both stages reference
  `nginx:1.27-alpine@sha256:...`; the tag is kept for readability but the
  digest is what the build and runtime actually resolve to, so a rebuild
  today and in six months produces the same base layer even if the tag
  moves. `scripts/check-pins.sh` enforces this on every `make validate`
  — an unpinned `FROM` line fails the check.
- **Multi-stage build** — a short-lived build stage renders the landing
  page template with build metadata; only the finished content crosses
  into the runtime stage. The runtime image stays a plain static server.
- **Non-root runtime** — the worker runs as the `nginx` user; the image
  does not need a privileged container.
- **Healthcheck built in** — the image declares a `HEALTHCHECK` using
  `wget` against `/healthz`, so `docker run` / compose get liveness for free.
- **Hardened compose service** — the service runs with a read-only root
  filesystem (nginx's cache/pid dirs live on small `tmpfs` mounts), all
  kernel capabilities dropped, `no-new-privileges`, an `init` process to
  reap zombies, CPU/memory limits, log rotation, and the port bound to
  `127.0.0.1` only — the same posture you would want for a real deployment.
- **Server hardening** — nginx hides its version, sends baseline security
  headers (nosniff, frame denial, referrer policy), caps request bodies,
  and applies a sane cache policy (assets cacheable for an hour, the
  `/healthz` probe never cached). `scripts/test-nginx-conf.sh` locks these
  invariants into `make validate`.
- **Template drift guard** — `scripts/check-render.sh` fails validation if
  the rendered page still contains any `${...}` placeholder, so a template
  variable that `render.sh` doesn't know about is caught at check time
  instead of shipping a page full of raw placeholders.
- **Small context** — `.dockerignore` keeps local working files and the
  git metadata out of the build.

## Validation

```bash
make validate                                # lint + syntax + checks + tests + render
hadolint Dockerfile                          # image-lint (run locally)
make syntax                                  # sh -n on every script (shellcheck if present)
scripts/check-pins.sh                        # digest-pin check (part of validate)
scripts/check-render.sh                      # placeholder-drift check (part of validate)
scripts/test-check-pins.sh                   # pin-check smoke tests (part of validate)
scripts/test-nginx-conf.sh                   # nginx config invariant tests (part of validate)
scripts/scan.sh [image]                      # trivy scan (optional; skips if absent)
docker compose config                        # syntax-check the compose file
```

On a podman-only box, `make build DOCKER=podman` etc. work unchanged — see
`docs/runtime-capsule.md`. For the CVE/SBOM story, see `docs/security.md`.

This repo is validation-light on purpose: none of these steps need a build
or a cluster.