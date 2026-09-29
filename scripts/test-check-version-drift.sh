#!/bin/sh
# Smoke test for scripts/check-version-drift.sh: a reference matching the
# pinned tag must pass, a stale one must fail with a non-zero exit code.
set -eu

cd "$(dirname "$0")/.."

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT INT TERM

printf 'FROM nginx:1.29-alpine@sha256:deadbeef\n' > "$tmpdir/Dockerfile"

# 1. current repo files (already in sync) -> exit 0
printf 'PASS: '
if scripts/check-version-drift.sh >/dev/null 2>&1; then
  echo 'repo files accepted'
else
  echo 'FAIL: repo files rejected'; exit 1
fi

# 2. a doc referencing the pinned tag -> exit 0
printf 'uses nginx:1.29-alpine under the hood\n' > "$tmpdir/fresh.md"
printf 'PASS: '
if scripts/check-version-drift.sh "$tmpdir/Dockerfile" "$tmpdir/fresh.md" >/dev/null 2>&1; then
  echo 'matching tag accepted'
else
  echo 'FAIL: matching tag rejected'; exit 1
fi

# 3. a doc referencing a stale tag -> exit 1
printf 'uses nginx:1.27-alpine under the hood\n' > "$tmpdir/stale.md"
printf 'FAIL? '
if scripts/check-version-drift.sh "$tmpdir/Dockerfile" "$tmpdir/stale.md" >/dev/null 2>&1; then
  echo 'FAIL: stale tag accepted'; exit 1
fi
echo 'stale tag rejected'

# 4. a doc with no version mention at all -> exit 0 (nothing to compare)
printf 'no version mentioned here\n' > "$tmpdir/silent.md"
printf 'PASS: '
if scripts/check-version-drift.sh "$tmpdir/Dockerfile" "$tmpdir/silent.md" >/dev/null 2>&1; then
  echo 'silent doc accepted'
else
  echo 'FAIL: silent doc rejected'; exit 1
fi

echo 'check-version-drift tests: ok'
