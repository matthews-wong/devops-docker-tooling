# Security workflow: CVE scanning + SBOM

The image is only as trustworthy as its base layers, so the repo ships a
scan story alongside the build story. Everything here runs through
[Trivy](https://aquasecurity.github.io/trivy/) — one tool for
misconfigurations, OS/library CVEs, and SBOM export.

## Install

```bash
# a single static binary; no daemon, no database to seed (vuln DB is
# downloaded on first run and cached locally)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
```

## The three scans

```bash
scripts/scan.sh                # all three, default image docker-tooling-site:dev
scripts/scan.sh docker-tooling-site:v1.2.0   # scan a specific built image
```

1. **Misconfiguration scan** — `trivy config .` lints the Dockerfile and
   compose file against its built-in best-practice checks, offline, no image
   needed. HIGH/CRITICAL findings fail with exit 1.
2. **CVE scan** — `trivy image --ignore-unfixed ...` checks the built image's
   OS packages and language dependencies against the vulnerability database.
   `--ignore-unfixed` only reports issues that have a fix available, which
   keeps the noise down when triaging.
3. **SBOM export** — `trivy image --format cyclonedx` writes a CycloneDX
   software bill of materials (`sbom.cdx.json`) listing every component in
   the image. Keep it alongside a release so consumers can attest what
   shipped.

## Policy

- HIGH/CRITICAL findings fail the scan (exit 1); MEDIUM/LOW are reported but
  don't block — the demo image is a pinned `nginx:1.27-alpine`, so any new
  CVE is a known, reviewable delta.
- Trivy is optional tooling: if it isn't installed, `scripts/scan.sh` prints
  a note and exits 0 so `make validate` stays green in thin environments.
  Install it and the gate hardens automatically.
- Digest-pinning both `FROM` stages (enforced by `scripts/check-pins.sh`)
  means a scan result maps to exactly one base layer set — a scan of
  `@sha256:65645c...` today is reproducible tomorrow.

## What this does not cover

No runtime secret scanning or image-signing here — the demo image carries no
secrets and nothing is published. For a registry-pushed image, add
`cosign sign` + `cosign verify` on top of the SBOM for a full attestation
chain.
