# Security policy

This is a small reference project (a static site behind hardened nginx), not
a production service, but the same reporting norms apply.

## Reporting a vulnerability

Please open a private report via
[GitHub Security Advisories](https://github.com/matthews-wong/devops-docker-tooling/security/advisories/new)
rather than a public issue. Include the affected file(s), the version or
commit, and reproduction steps if applicable.

## Scope

This repo ships build- and config-time hardening (digest-pinned base image,
non-root runtime, dropped capabilities, security headers) and a scan
workflow — see [`docs/security.md`](docs/security.md) for how CVE/SBOM
scanning is wired up and what it does and doesn't cover.
