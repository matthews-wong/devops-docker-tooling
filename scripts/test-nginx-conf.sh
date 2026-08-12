#!/bin/sh
# Smoke test for nginx.conf: assert the hardened server invariants hold.
# Runs offline (no nginx binary needed) by grepping the config file for the
# posture this repo commits to. If a future edit drops a header or opens
# the privileged port, this fails before the image is even built.
set -eu

cd "$(dirname "$0")/.."

conf="nginx.conf"
[ -f "$conf" ] || { echo "test-nginx-conf: $conf not found" >&2; exit 2; }

fail=0
assert_present() {
  # $1 = description, $2 = grep pattern
  if grep -Eq "$2" "$conf"; then
    echo "PASS: $1"
  else
    echo "FAIL: $1 (missing '$2')" >&2
    fail=1
  fi
}
assert_absent() {
  # $1 = description, $2 = grep pattern
  if grep -Eq "$2" "$conf"; then
    echo "FAIL: $1 (found '$2')" >&2
    fail=1
  else
    echo "PASS: $1"
  fi
}

assert_present "unprivileged port only (8080)" 'listen[[:space:]]+8080;'
assert_absent  "no privileged port 80"        'listen[[:space:]]+80[^0-9]'
assert_present "server version hidden"        'server_tokens[[:space:]]+off;'
assert_present "request body capped"          'client_max_body_size[[:space:]]+1k;'
assert_present "nosniff header"               'X-Content-Type-Options[[:space:]]+nosniff'
assert_present "frame denial header"          'X-Frame-Options[[:space:]]+DENY'
assert_present "referrer policy header"       'Referrer-Policy[[:space:]]+no-referrer'
assert_present "liveness probe endpoint"      'location[[:space:]]+=[[:space:]]+/healthz'
assert_present "probe not cached"             'Cache-Control[[:space:]]+"no-store"'
assert_present "static assets cacheable"      'expires[[:space:]]+1h;'

exit "$fail"