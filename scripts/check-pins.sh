#!/bin/sh
# Verify every FROM instruction in the Dockerfile pins its base image by
# digest (name@sha256:...). Unpinned or malformed pins fail the build early,
# so a future edit can't silently reintroduce floating base images.
#
# Usage: scripts/check-pins.sh [Dockerfile]   (default: ./Dockerfile)
set -eu

DOCKERFILE="${1:-Dockerfile}"
[ -f "$DOCKERFILE" ] || { echo "check-pins: $DOCKERFILE not found" >&2; exit 2; }

fail=0
lineno=0
while IFS= read -r line || [ -n "$line" ]; do
  lineno=$((lineno + 1))
  case "$line" in
    FROM*)
      # shellcheck disable=SC2086
      set -- $line
      shift  # drop FROM
      # Skip build flags that can precede the image (--platform=...,
      # --os=..., --architecture=...), e.g. multi-arch builds.
      while [ "${1#--}" != "$1" ]; do shift; done
      image="${1:-}"
      if ! printf '%s\n' "$image" | grep -Eq '^[^@]+@sha256:[0-9a-f]{64}$'; then
        echo "check-pins: line $lineno: unpinned base image '$image' (want name@sha256:<64 hex>)" >&2
        fail=1
      fi
      ;;
  esac
done < "$DOCKERFILE"

if [ "$fail" -eq 0 ]; then
  echo "check-pins: all FROM images are digest-pinned"
fi
exit "$fail"