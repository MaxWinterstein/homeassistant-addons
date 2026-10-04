#!/usr/bin/env bash
#
# Emulates the `#!/usr/bin/with-contenv bashio` shebang for tests.
#
# Used via BASH_ENV, so the script under test is genuinely *executed* the way
# s6 executes it in the container, rather than sourced into the test shell:
#
#   BASH_ENV=tests/helpers/drivers/contenv.bash bash <script>
#
# Two things that shebang provides and the scripts rely on:
#   - the bashio::* functions
#   - `set -e` and `set -o pipefail` (see planefence/CLAUDE.md)

# shellcheck source=/dev/null
. "${BASHIO_STUB}"

set -eo pipefail
