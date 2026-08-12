#!/bin/sh
# Render a template through scripts/render.sh and fail if ANY ${...}
# placeholder survives. This catches template drift: when content gains
# a new variable but render.sh (and its envsubst/sed substitution lists)
# isn't updated to match, the check breaks the build instead of shipping
# a page full of raw placeholders.
#
# Usage: scripts/check-render.sh [template]   (default: content/index.html)
set -eu

cd "$(dirname "$0")/.."

src="${1:-content/index.html}"
[ -f "$src" ] || { echo "check-render: $src not found" >&2; exit 2; }

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT INT TERM

BUILD_VERSION="${BUILD_VERSION:-check}" BUILD_DATE="${BUILD_DATE:-2026-01-01}" \
  scripts/render.sh "$src" > "$tmp"

if grep -E '\$\{[A-Za-z_][A-Za-z0-9_]*\}' "$tmp"; then
  echo "check-render: unresolved placeholder(s) in rendered page" >&2
  exit 1
fi
echo "check-render: no unresolved placeholders"