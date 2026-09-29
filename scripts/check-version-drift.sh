#!/bin/sh
# Verify every descriptive reference to the base image tag (README, docs,
# the landing page) matches the tag actually pinned in the Dockerfile's
# FROM lines. Docker only reads the digest, so a bumped tag with a stale
# prose reference elsewhere builds fine and ships a misleading page - this
# catches that drift at check time instead of leaving it for a reader to
# notice.
#
# Usage: scripts/check-version-drift.sh   (run from repo root)
set -eu

cd "$(dirname "$0")/.."

DOCKERFILE="Dockerfile"
[ -f "$DOCKERFILE" ] || { echo "check-version-drift: $DOCKERFILE not found" >&2; exit 2; }

pinned="$(grep -m1 '^FROM' "$DOCKERFILE" | grep -oE 'nginx:[0-9]+\.[0-9]+-alpine')"
[ -n "$pinned" ] || { echo "check-version-drift: no nginx:X.Y-alpine tag found in $DOCKERFILE" >&2; exit 2; }

# Files that describe the running image in prose; test fixtures under
# scripts/ intentionally use arbitrary version literals and are excluded.
files="README.md content/index.html docs/security.md"

fail=0
for f in $files; do
  [ -f "$f" ] || continue
  found="$(grep -noE 'nginx:[0-9]+\.[0-9]+-alpine' "$f" || true)"
  [ -n "$found" ] || continue
  stale="$(printf '%s\n' "$found" | grep -v ":${pinned}$" || true)"
  if [ -n "$stale" ]; then
    echo "check-version-drift: $f references a stale tag (want $pinned):" >&2
    printf '%s\n' "$stale" >&2
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "check-version-drift: all descriptive references match the pinned tag ($pinned)"
fi
exit "$fail"
