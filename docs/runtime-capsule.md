# Runtime capsule: Docker vs Podman

The build story here is deliberately daemon-agnostic — every Dockerfile and
compose file in this repo runs under podman with no changes. This page is
the cheat sheet for a podman-only box.

## Why podman

- **Rootless by default** — the daemon runs in userspace, so `docker build`
  and `docker run` need no root and no daemon process. On a workstation or
  CI runner without a Docker daemon this is the fastest path.
- **Same CLI** — podman is a drop-in for almost every `docker` subcommand,
  which is why the Makefile takes `DOCKER ?= docker`:

```bash
make build DOCKER=podman          # podman build -t docker-tooling-site .
make up   DOCKER=podman           # podman compose up -d --build
```

## Compose: two options

- `podman compose` — the built-in compose v2 plugin (needs `podman-compose`
  or the `docker-compose` binary on PATH for some distros; modern podman
  ships a compose provider).
- `podman-compose` — the standalone Python implementation. Slower and less
  feature-complete than the compose v2 spec, but fine for the single-service
  file in this repo. `deploy.resources` limits are honored by
  `podman-compose` as container resource limits; `init:`, `read_only:` and
  `tmpfs:` map directly to podman flags.

## Where the CLI actually differs

| docker | podman | note |
|---|---|---|
| `docker info` | `podman info` | same shape, different socket path |
| `docker run --rm -it` | `podman run --rm -it` | identical flags |
| `docker compose up` | `podman compose up` | needs compose provider |
| `docker buildx build` | `podman build` | podman builds multi-arch with `--platform` natively |
| `docker context use` | `podman system connection` | machine/remote wiring |

## Rootless gotchas worth knowing

- **Networking** — rootless containers use slirp4netns/pasta instead of a
  bridged `docker0`, so `--network host` behaves differently and container
  IPs are NAT'd. Port publishing (`127.0.0.1:8080:8080` in this repo's
  compose file) works the same.
- **Volumes** — rootless bind-mounts keep the host uid mapping via
  `--userns=keep-id`; a file owned by uid 1000 on the host may look like a
  different uid inside the container unless you pass `--userns=keep-id`.
  The demo image avoids this entirely by baking content into the image.
- **Socket** — the rootless socket lives at
  `$XDG_RUNTIME_DIR/podman/podman.sock` (`/run/user/1000/podman/...`), not
  `/var/run/docker.sock`. Point compose or a tool at it via
  `DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock` if it refuses to
  find the daemon.

## Verdict for this repo

`make build DOCKER=podman && make up DOCKER=podman` is a fully supported
path. The compose file uses only the common subset of the spec, and the
image itself is a plain nginx static server — the least interesting thing to
get wrong across runtimes.
