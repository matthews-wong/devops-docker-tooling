#!/bin/sh
# Scan wrapper around Trivy (https://aquasecurity.github.io/trivy):
#   1. config scan - offline misconfiguration check of Dockerfile + compose
#   2. image scan  - CVE scan of a built image (image must exist locally)
#   3. SBOM export - CycloneDX software bill of materials for the image
#
# Usage: scripts/scan.sh [image]   (default: docker-tooling-site:dev)
#
# Trivy is optional tooling: when it is not on PATH the scan is skipped with
# a note so `make validate` stays green on boxes without it. When present,
# any HIGH/CRITICAL finding fails the scan (exit 1).
set -eu

IMAGE="${1:-docker-tooling-site:dev}"

if ! command -v trivy >/dev/null 2>&1; then
  echo "scan: trivy not found - install from https://aquasecurity.github.io/trivy to enable (skipped)" >&2
  exit 0
fi

echo "== 1/3 trivy config: Dockerfile + compose misconfigurations =="
trivy config --exit-code 1 --severity HIGH,CRITICAL .

echo "== 2/3 trivy image: CVE scan of $IMAGE =="
trivy image --ignore-unfixed --exit-code 1 --severity HIGH,CRITICAL "$IMAGE"

echo "== 3/3 trivy image: CycloneDX SBOM -> sbom.cdx.json =="
trivy image --format cyclonedx --output sbom.cdx.json "$IMAGE"
echo "scan: done, sbom written to sbom.cdx.json"