# OrbStack test bench

A disposable OrbStack VM that gives this repository two things it did not have
before: a place to run **real Docker builds** and a place to run a **real Home
Assistant + Supervisor instance** — without granting either of those to the
Mac or to the Claude sandbox.

## Why this exists

CI already covers the outside of each add-on: `frenck/action-addon-linter`
validates the manifests and `home-assistant/builder` proves the images build.
What nothing covered was actually _running_ an add-on against a real
Supervisor, and doing it somewhere throwaway.

The Home Assistant add-on docs tell you to use their devcontainer. That image
needs `--privileged` and docker-in-docker, which is a lot of trust to hand to
your main machine. Putting it in a VM you can delete in one command is a better
trade.

## What runs where

| Layer                                         | Needs               | Runs where                   |
| --------------------------------------------- | ------------------- | ---------------------------- |
| Shell unit tests, manifest/consistency checks | nothing             | Claude sandbox, your Mac, CI |
| Image builds, container smoke tests           | Docker              | **this VM** (or CI)          |
| Real HA + Supervisor, add-on install, ingress | Docker + privileged | **this VM**                  |

The fast layers deliberately need nothing, so they stay the inner loop. This
VM is for the slow, privileged, dirty work.

## Security model

Read this before running `provision.sh`.

The VM exposes its Docker daemon over **plain, unauthenticated TCP** on port 2375. Anyone who can reach that port has root-equivalent control of the VM.
That is a deliberate trade-off, and it is only acceptable because of the
compensating controls:

- **The Claude sandbox has no SSH client**, so `DOCKER_HOST=ssh://` is not
  available. TCP is the only bridge that works, which is why the VM must be
  worthless rather than merely well-configured.
- **Mac file sharing is removed** (`vm/10-harden.sh`). OrbStack mounts your
  entire Mac filesystem at `/mnt/mac` by default; we unmount it and re-unmount
  on every boot. OrbStack has no documented switch for this, so it is
  best-effort — `doctor.sh` check 4 verifies it actually stuck. **Trust the
  doctor, not the script.**
- **Ports stay off the LAN** — `provision.sh` sets
  `machines.expose_ports_to_lan=false` so only the Mac and containers on it can
  reach the daemon.
- **No credentials live in the VM.** No SSH keys, no tokens, no API keys, no
  `git` push credentials. The repo arrives as a one-way copy (`task vm:sync`),
  not a mount.
- **The HA instance is a test instance.** Do not restore a backup of your real
  Home Assistant into it, and do not put real integration credentials in it.

If the VM ever misbehaves, the recovery path is `task vm:destroy` and you have
lost nothing. Keep it that way — the moment something valuable lives in there,
this whole design stops being sound.

## Quick start

On the Mac:

```bash
./.orbstack/provision.sh     # create + harden + provision (idempotent)
task vm:ha:up                # start Home Assistant + Supervisor
open http://ha-dev.orb.local:8123
```

In the Claude sandbox:

```bash
./.orbstack/sandbox-setup.sh                       # static docker client only
export DOCKER_HOST=tcp://ha-dev.orb.local:2375
./.orbstack/doctor.sh                              # verify every hop
```

## Commands

| Command                   | Where   | What                                          |
| ------------------------- | ------- | --------------------------------------------- |
| `task vm:up`              | Mac     | Create/reprovision the VM                     |
| `task vm:sync`            | Mac     | Copy the working tree into the VM             |
| `task vm:ha:up`           | Mac     | Start HA + Supervisor (detached)              |
| `task vm:ha:logs`         | Mac     | Follow the Supervisor logs                    |
| `task vm:ha:down`         | Mac     | Stop the HA instance                          |
| `task vm:shell`           | Mac     | Root shell in the VM                          |
| `task vm:destroy`         | Mac     | Delete the VM and everything in it            |
| `task vm:doctor`          | either  | Verify DNS → daemon → client → isolation → HA |
| `task sandbox:docker-cli` | sandbox | Install the static docker client              |

`doctor.sh --deep` additionally runs a real container on each of
`linux/amd64`, `linux/arm64` and `linux/arm/v7` to prove the binfmt handlers
work, which is what the multi-arch builds in `taskfile.yml` depend on.

## Why Claude Code stays _outside_ the VM

It is tempting to move everything — editor, tooling, Claude Code itself — into
the VM and be done with one box. Deliberately not doing that:

- **Credentials.** Claude Code needs its auth token. Moving Claude in means
  putting that token in the same box that runs `--privileged` containers behind
  an unauthenticated Docker socket. That collapses two trust zones into one, in
  the wrong direction. Today the token stays in the sandbox, outside the VM.
- **The sandbox is already the right shape.** It is purpose-built, has no
  Docker, no privileges and no SSH. Replacing it with a hand-rolled VM trades a
  known-good boundary for one we would have to maintain ourselves.
- **The bridge already solves the actual problem.** The only thing the sandbox
  was missing was the ability to run containers, and `DOCKER_HOST` provides
  exactly that — nothing more.

What genuinely _would_ improve by moving in: one less hop, no open TCP port
(a local unix socket needs none), no `vm:sync` step, and a Linux environment
identical to CI. If you ever decide the port bothers you more than the
credential exposure does, that is the trade you are making — and
`vm/30-docker-tcp.sh` becomes unnecessary.

## Troubleshooting

**`ha-dev.orb.local` does not resolve from the sandbox.** Check `orb list`
shows the machine running. OrbStack DNS reaches containers on its own engine —
`doctor.sh` check 1 distinguishes "machine missing" from "not on OrbStack's
network at all".

**Daemon unreachable but the machine is up.** `task vm:shell`, then
`systemctl status docker`. The TCP listener is a drop-in at
`/etc/systemd/system/docker.service.d/10-tcp-listener.conf`.

**Doctor check 4 fails (Mac files visible).** The hardening did not stick.
Re-run `orb -m ha-dev -u root /usr/local/sbin/no-mac-mount`, and check whether
a newer OrbStack changed how `/mnt/mac` is mounted. Do not use the Docker
bridge until this check passes.

**`docker run` hangs forever (but `docker version` works).** An inspecting
HTTP proxy is intercepting the connection. `docker run` attaches via HTTP
connection hijacking, which such proxies break, and the CLI hangs instead of
erroring. Add `.orb.local` to `NO_PROXY` — for the Claude sandbox this is set
in `.vibepod/config.yaml`. Note that `timeout` alone will not rescue you here:
`docker run` forwards SIGTERM to the container rather than exiting, so a
`timeout -k` that escalates to SIGKILL is required.

**HA takes a long time to come up.** First boot pulls HA Core inside
docker-in-docker. `task vm:ha:logs` shows progress; several minutes is normal.
