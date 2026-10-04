#!/usr/bin/env bash
#
# Minimal stand-in for bashio, so the add-on cont-init scripts can run under
# bats without a Home Assistant container.
#
# Only the surface the add-on scripts actually use is implemented. Log output
# goes to stderr, matching bashio, so tests can assert on it separately from a
# script's real stdout.
#
# The real bashio also turns on `set -e` and `set -o pipefail` via its
# with-contenv shebang; the test drivers do that explicitly so the scripts run
# under the same failure semantics they get in production.

bashio::log.info() { printf '[INFO] %s\n' "$*" >&2; }
bashio::log.warning() { printf '[WARNING] %s\n' "$*" >&2; }
bashio::log.error() { printf '[ERROR] %s\n' "$*" >&2; }
bashio::log.debug() { printf '[DEBUG] %s\n' "$*" >&2; }
bashio::log.notice() { printf '[NOTICE] %s\n' "$*" >&2; }
bashio::log.fatal() { printf '[FATAL] %s\n' "$*" >&2; }
bashio::log.magenta() { printf '[MAGENTA] %s\n' "$*" >&2; }
bashio::log.cyan() { printf '[CYAN] %s\n' "$*" >&2; }

# Some add-on scripts guard on these; keep them predictable in tests.
bashio::config.true() { return 1; }
bashio::config.false() { return 0; }
bashio::var.has_value() { [ -n "${1:-}" ]; }
bashio::var.is_empty() { [ -z "${1:-}" ]; }
bashio::fs.file_exists() { [ -f "${1:-}" ]; }
