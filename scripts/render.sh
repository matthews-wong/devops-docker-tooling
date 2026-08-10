#!/bin/sh
# Render the landing page template, substituting build metadata.
# Used both inside the image build (envsubst ships with nginx:alpine) and
# locally on a dev box that has neither Docker nor gettext (sed fallback).
#
# Usage: BUILD_VERSION=1.2.0 BUILD_DATE=2026-08-10 ./scripts/render.sh > page.html
set -eu

BUILD_VERSION="${BUILD_VERSION:-dev}"
BUILD_DATE="${BUILD_DATE:-$(date -u +%Y-%m-%d)}"
SRC="${1:-content/index.html}"

if command -v envsubst >/dev/null 2>&1; then
  # shellcheck disable=SC2016 - literal list on purpose: only these two
  # variables are substituted, everything else passes through untouched.
  envsubst '${BUILD_VERSION} ${BUILD_DATE}' < "$SRC"
else
  sed -e "s/\${BUILD_VERSION}/${BUILD_VERSION}/g" \
      -e "s/\${BUILD_DATE}/${BUILD_DATE}/g" "$SRC"
fi