# VibePod sandbox configuration

Claude Code runs in a [VibePod](https://vibepod.dev) container rather than
directly on the Mac. This directory customises that sandbox.

## Why an overlay

The base `vibepod/claude` image ships bash, jq, python3, node and git — but not
`bats`, `shellcheck`, `task`, `yq`, `uv` or a `docker` client, all of which the
tests in this repository need. The sandbox user is unprivileged (no root, no
sudo, no pip), so tools cannot be installed at runtime in any durable way.

`overlay/claude/Dockerfile` is a FROM-less fragment that VibePod appends to the
base image, building a workspace-local image cached by content hash. Editing
the fragment triggers a rebuild on the next `vp run`; force one with:

```bash
vp run claude --rebuild-overlay
```

**Changes take effect on the next container start, not the current session.**

## What the overlay adds

| Tool                      | For                                               |
| ------------------------- | ------------------------------------------------- |
| `bats` + support/assert   | Shell unit tests for the add-on cont-init scripts |
| `shellcheck`, `shfmt`     | Linting and formatting the `bashio` scripts       |
| `python3-yaml`            | Reading `config.yaml` in the consistency checks   |
| `task`                    | Running `taskfile.yml` from inside the sandbox    |
| `yq`                      | YAML surgery, same tool the CI workflows use      |
| `uv`, `uvx`, `pre-commit` | Matching the `pyproject.toml` workflow            |
| `docker` + `buildx`       | Client only — drives the OrbStack VM's daemon     |

Tests load the bats helpers via `bats_load_library bats-support`, which works
because the overlay sets `BATS_LIB_PATH`.

## Docker without a daemon

The sandbox deliberately has no Docker daemon and no privileges. `DOCKER_HOST`
in `config.yaml` points the client at the disposable OrbStack VM, so container
work happens there instead. Claude Code itself stays outside that VM on
purpose — the reasoning is in [`../.orbstack/README.md`](../.orbstack/README.md).

If the VM is not running, `docker` commands simply fail; nothing else breaks.
`.orbstack/doctor.sh` diagnoses the chain.

### The proxy exemption

VibePod routes sandbox traffic through an inspecting proxy (mitmproxy). Plain
Docker API calls — `version`, `images`, `pull` — pass through it fine, but
`docker run` attaches to the container using HTTP connection hijacking, which
the proxy breaks. The failure mode is nasty: the CLI **hangs** rather than
returning an error, and `timeout` alone will not kill it because `docker run`
forwards SIGTERM to the container instead of exiting.

So `config.yaml` adds `.orb.local` to `NO_PROXY`. Scope worth being clear
about: this exempts **only** the local test VM. Internet egress still goes
through the proxy, so the exemption does not create a way out of the sandbox —
but Docker API traffic to the VM is no longer visible to the proxy's logging.

`doctor.sh` detects a missing exemption and applies it for its own run, so it
diagnoses this instead of hanging.

## Note on `.venv`

`../.venv` is created on the Mac by `uv` and is a macOS-native virtualenv, so
it is unusable inside this Linux container. Use the overlay's `uv` to make a
separate environment if you need one — do not try to activate `../.venv` here.
