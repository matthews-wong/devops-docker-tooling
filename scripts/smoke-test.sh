#!/usr/bin/env bash
# Run the image, then poll the static page and the healthz probe before
# tearing the container down. Fails loudly (with logs) if either never
# comes up, so a broken render or nginx.conf is caught before it ships.
#
# Usage: scripts/smoke-test.sh [image]   (default: docker-tooling-site:ci)
set -euo pipefail

image="${1:-docker-tooling-site:ci}"
port="${SMOKE_PORT:-18080}"
container_name="docker-tooling-site-smoke-$$"

cleanup() {
  # shellcheck disable=SC2317  # invoked via trap, not unreachable
  docker rm -f "$container_name" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d --name "$container_name" -p "127.0.0.1:${port}:8080" "$image" >/dev/null

for _ in $(seq 1 10); do
  if curl -sf "http://127.0.0.1:${port}/healthz" | grep -q '^ok$' \
      && curl -sf "http://127.0.0.1:${port}/" | grep -q 'static site container'; then
    echo "smoke test passed"
    exit 0
  fi
  sleep 1
done

echo "smoke test failed: service did not become healthy" >&2
docker logs "$container_name" >&2 || true
exit 1
