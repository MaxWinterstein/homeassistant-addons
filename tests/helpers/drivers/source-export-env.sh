#!/usr/bin/env bash
#
# Test driver for planefence/export-env-from-config.sh.
#
# That script is meant to be *sourced* by a cont-init script running under
# `#!/usr/bin/with-contenv bashio`, which supplies the bashio functions and
# turns on `set -e` / `set -o pipefail`. This driver reproduces that context
# exactly, then dumps the resulting environment so tests can assert on which
# variables were exported and with what values.
#
# Required environment:
#   BASHIO_STUB         path to tests/helpers/bashio.bash
#   EXPORT_ENV_SCRIPT   path to the script under test
#   HA_OPTIONS_FILE     path to the fake options.json
#
# Environment variables are printed to stdout as KEY=value after a marker, so
# log output (which bashio sends to stderr) never interferes.

set -eo pipefail

# shellcheck source=/dev/null
. "${BASHIO_STUB}"

# shellcheck source=/dev/null
. "${EXPORT_ENV_SCRIPT}"

echo "---ENV---"
# Print every variable the script may have exported. `env -0` keeps values
# containing newlines intact, and the NUL is translated to a marker so the
# output stays line-oriented for bats assertions.
env -0 | tr '\0' '\n'
