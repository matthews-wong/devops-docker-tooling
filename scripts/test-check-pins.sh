#!/bin/sh
# Smoke test for scripts/check-pins.sh: a pinned Dockerfile must pass,
# an unpinned one must fail with a non-zero exit code.
set -eu

cd "$(dirname "$0")/.."

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT INT TERM

# 1. current Dockerfile (every FROM digest-pinned) -> exit 0
printf 'PASS: '
if scripts/check-pins.sh >/dev/null 2>&1; then
  echo 'pinned Dockerfile accepted'
else
  echo 'FAIL: pinned Dockerfile rejected'; exit 1
fi

# 2. unpinned FROM -> exit 1
printf 'FROM nginx:1.27-alpine\n' > "$tmpdir/unpinned.Dockerfile"
printf 'FAIL? '
if scripts/check-pins.sh "$tmpdir/unpinned.Dockerfile" >/dev/null 2>&1; then
  echo 'FAIL: unpinned image accepted'; exit 1
fi
echo 'unpinned image rejected'

# 3. malformed digest (short sha) -> exit 1
printf 'FROM nginx:1.27-alpine@sha256:abc\n' > "$tmpdir/short.Dockerfile"
printf 'FAIL? '
if scripts/check-pins.sh "$tmpdir/short.Dockerfile" >/dev/null 2>&1; then
  echo 'FAIL: short digest accepted'; exit 1
fi
echo 'short digest rejected'

echo 'check-pins tests: ok'