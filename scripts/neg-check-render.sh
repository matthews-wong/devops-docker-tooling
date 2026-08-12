#!/bin/sh
# Negative test for check-render.sh: a template with a fresh variable must fail.
set -eu
cd "$(dirname "$0")/.."
d="$(mktemp -d)"
trap 'rm -r "$d"' EXIT INT TERM
cp content/index.html "$d/index.html"
printf '<p>${FRESH_VAR}</p>\n' >> "$d/index.html"
# render.sh takes the source path as $1; check-render.sh defaults to
# content/index.html, so simulate drift by pointing render.sh at the
# polluted copy directly.
if BUILD_VERSION=x BUILD_DATE=y scripts/render.sh "$d/index.html" | grep -q '\${FRESH_VAR}'; then
  echo "negative: render keeps unknown placeholder as expected"
else
  echo "negative: placeholder was substituted - fixture broken" >&2
  exit 1
fi
if scripts/check-render.sh "$d/index.html" >/dev/null 2>&1; then
  echo "negative: FAIL - check-render accepted unresolved placeholder" >&2
  exit 1
else
  echo "negative: check-render rejects unresolved placeholder (exit != 0)"
fi
