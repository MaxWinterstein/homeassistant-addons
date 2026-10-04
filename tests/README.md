# Tests

```bash
task test          # the fast layers, ~2 seconds, no Docker
task test:bats     # shell unit tests
task test:addons   # add-on config consistency
task check:shellcheck

task test:smoke    # build and boot the real add-on container (needs Docker)

task ha:up                    # start a real Home Assistant + Supervisor
task test:ha -- planefence    # install the add-on into it and verify it runs
```

Nothing here needs Docker or a running Home Assistant. That is deliberate: the
add-ons are thin wrappers, and almost all of their own logic is the translation
from `options.json` into a config file or environment. That translation is
where the bugs are, and it can be tested in about a second.

## What is tested where

| Layer                                  | Needs               | Where it runs                      |
| -------------------------------------- | ------------------- | ---------------------------------- |
| These tests                            | nothing             | anywhere, incl. the Claude sandbox |
| Image builds, container smoke tests    | Docker              | the OrbStack VM, or CI             |
| Upstream drift (`tests/drift/`)        | Docker              | CI on every PR, or the OrbStack VM |
| Real HA + Supervisor, ingress, install | Docker + privileged | the OrbStack VM                    |

The Docker-based layers live in [`../.orbstack/README.md`](../.orbstack/README.md).

## `tests/planefence/*.bats`

Unit tests for the planefence cont-init scripts, which are the most logic-heavy
in the repo. `bashio`, `curl` and `sleep` are stubbed; the scripts run against a
temp directory.

Two of these tests are named `REGRESSION v0.1.3`. That release called
`unset_config` for every optional key whose add-on option was empty, which wiped
the upstream template defaults — including `PF_ALERTLIST`, without which
planefence crash-loops. The script still carries migration code for configs
damaged by it. Those tests exist so it cannot happen again.

### How the scripts are made testable

The scripts take an `HA_ROOT` prefix (and `HA_OPTIONS_FILE`) which is **empty in
production**, so the real absolute container paths apply unchanged. Tests point
it at a temp directory. This is the only concession the production scripts make
to being tested.

`tests/helpers/drivers/contenv.bash` reproduces what the
`#!/usr/bin/with-contenv bashio` shebang provides — the `bashio::*` functions
plus `set -e` and `set -o pipefail` — so scripts run under the same failure
semantics they get from s6.

### These tests have been mutation-tested

Each suite was checked by deliberately breaking the code it covers and
confirming the right tests fail. That caught one test which passed against
broken code: the sed-escaping test appended a new key instead of rewriting an
existing one, so it never exercised the escaping at all. If you add a test
here, break the thing it covers once and watch it go red.

## `tests/check_addons.py`

Cross-cutting checks on every add-on directory: required config fields, valid
architectures, `options` ↔ `schema` agreement, valid translation JSON, and that
the version in the config matches the newest `CHANGELOG.md` entry — which
mechanically enforces the version-bump rule in `CLAUDE.md`.

Note that add-on **slugs deliberately do not match directory names** in this
repo (`fr24-sharing-key-generator` → `fr24sharingkeygenerator`), because
changing a slug breaks existing installations. There is no check for that.

```bash
python3 tests/check_addons.py --strict     # warnings fail too
python3 tests/check_addons.py planefence   # one add-on
ADDONS_ROOT=/some/fixtures python3 tests/check_addons.py
```

## `tests/smoke/planefence.sh`

Builds the real add-on image, boots it with a fake Supervisor environment, and
asserts on the result: the config keys translated from `options.json`, the
upstream template defaults that must survive, the
`/run/ha-planefence-ready` handshake, the persist symlink, zero restarts, and
an HTTP 200 from the web UI. Twenty checks, a couple of minutes.

Needs a Docker daemon, so it is **not** part of `task test`. From the Claude
sandbox it runs against the OrbStack VM via `DOCKER_HOST`.

```bash
task test:smoke
KEEP=1 tests/smoke/planefence.sh   # leave the container up to poke at
PORT=9000 tests/smoke/planefence.sh
ADDON_DIR=/tmp/mutated-copy tests/smoke/planefence.sh
```

Fixture data goes in through a **named volume**, not a bind mount, because bind
mounts resolve on the daemon's host — which is a different machine from the one
running the script when `DOCKER_HOST` points at the VM. Anything that needs
repo files inside the VM has the same constraint.

This suite was mutation-tested too: reintroducing the v0.1.3 bug makes exactly
the two template-default assertions fail. Worth knowing that the container
still reports **healthy with zero restarts** while carrying that bug — so a
"does it boot?" check would not have caught it. The specific config assertions
are the part doing the work.

## `tests/ha/` — the real Home Assistant

The top of the pyramid. `supervisor-up.sh` boots a genuine Home Assistant +
Supervisor in the OrbStack VM using the official add-on devcontainer;
`addon-test.sh <addon>` then installs your working tree into it and asserts it
runs:

```bash
task ha:up
task test:ha -- planefence
KEEP=1 tests/ha/addon-test.sh planefence   # leave it installed to click around
```

It syncs the working tree, comments out `image:` in the VM's copy so the
Supervisor **builds from your local Dockerfile** rather than pulling the last
release, installs, applies `<addon>/test/options.json` through the Supervisor
API, starts it, and checks state, container health, restart count, logs and the
ingress port. Then it uninstalls, unless `KEEP=1`.

This is the only layer that exercises the Supervisor parsing `config.yaml`,
building the image, the options round trip and ingress registration. Expect a
few minutes; the first `ha:up` pulls ~2GB of devcontainer plus ~600MB of HA Core.

### The devcontainer needs four workarounds

The official devcontainer image and the dev Supervisor it pulls have drifted
apart. `supervisor-up.sh` patches around each, marked `WORKAROUND` in the
source. Re-check them whenever the image is updated — they should eventually
become unnecessary:

1. **`-t` even when detached.** `supervisor_run` calls `stty` and exits 1
   without a TTY. Also, `devcontainer_bootstrap` is mode `0644`, so it must be
   run as `bash devcontainer_bootstrap` — as the official devcontainer.json does.
2. **`/run/supervisor` and a shared `/mnt/supervisor`.** HA Core bind-mounts
   the former, which nothing creates, and refuses to start unless the latter is
   a shared mount.
3. **`addons` → `apps` path drift.** The dev Supervisor looks for
   `/mnt/supervisor/apps/local/...` while `devcontainer_bootstrap` still mounts
   the workspace at the old `addons` path, so builds fail on a missing bind
   source. Note the REST API still uses `/addons/...`; only the CLI renamed.
4. **`docker_gateway_unprotected`.** The Supervisor applies gateway firewall
   rules through systemd over D-Bus, but PID 1 in the devcontainer is a shell
   script, so it marks the system unhealthy and blocks every install. Handled
   with `ha jobs options --ignore-conditions healthy`, which is a supported
   escape hatch and safe in a throwaway VM.

## `tests/drift/planefence.sh`

The planefence add-on writes its options into docker-planefence's
`planefence.config`, which starts as a copy of upstream's template. When
upstream renames a key, the add-on keeps writing the old name, the template's
default wins, and Planefence breaks, but only on fresh installs. That is what
happened with `FEEDER_LONG` → `FEEDER_LON` in `latest-build-1249`.

The check pulls the base image from `planefence/build.json` (the one CI and
publishing use), copies the template out without starting the container, and
fails if the add-on writes a key the template doesn't have. Deliberate
exceptions live in `tests/drift/planefence-allowed.txt`, each with a reason; a
renamed key kept for compatibility is marked `=>NEWKEY`, and the check then
also requires the new name to be written. It runs as its own CI job, so a
Renovate base-image bump that renames a key fails its own PR.

```sh
task test:drift
```

## `tests/shellcheck.sh`

Selects scripts by **shebang, not filename**: s6 `finish` scripts are often
`execlineb`, and linting those as bash yields only false positives.

Files in `tests/shellcheck-baseline.txt` are excused so the rest of the repo can
be gated — everything not listed must stay clean. Never add to that file; if a
script you are touching appears there, clean it up instead.

```bash
tests/shellcheck.sh --all   # ignore the baseline, show the real state
```
