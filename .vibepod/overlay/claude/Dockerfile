# VibePod overlay for the Claude sandbox.
#
# This is a FROM-less Dockerfile *fragment*: VibePod appends it to the
# vibepod/claude base image and builds a workspace-local image, cached by a
# hash of this file. Changing it triggers a rebuild on the next `vp run`;
# force one with `vp run claude --rebuild-overlay`.
#
# Why: the base sandbox has bash, jq, python3, node and git, but none of the
# tooling this repository's tests need. Everything below is what makes the
# fast (no-Docker) test layers runnable inside the sandbox, plus a docker
# *client* for driving the OrbStack VM — see .orbstack/README.md.
#
# Base image is Debian 12 (bookworm).
#
# Deliberately no USER instruction anywhere in this fragment. The base image
# leaves Config.User empty (so builds and containers start as root) and its
# entrypoint is what creates /home/claude and drops to the `claude` user,
# remapping that user's uid/gid to match the Mac user — 501:20 in the live
# sandbox versus 1000:1000 baked into the image. Pinning `USER claude` here
# breaks container startup outright; setting any USER at all risks breaking
# that remapping. Leave it to the entrypoint.

# ── Tooling from Debian ─────────────────────────────────────────────────
#   bats + helpers  shell unit tests for the add-on cont-init scripts
#   shellcheck      catches real bugs in the bashio scripts
#   shfmt           consistent shell formatting
#   python3-yaml    reading config.yaml in the consistency checks
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bats \
        bats-assert \
        bats-support \
        ca-certificates \
        curl \
        python3-yaml \
        shellcheck \
        shfmt \
    && rm -rf /var/lib/apt/lists/*

# Debian's bats helper libraries do not live in a single predictable root, so
# discover where dpkg actually put them and build a stable BATS_LIB_PATH out
# of symlinks. Fails the build loudly if the layout ever changes, rather than
# leaving tests to fail mysteriously later.
RUN set -eux; \
    mkdir -p /usr/local/lib/bats; \
    for pkg in bats-support bats-assert; do \
        load="$(dpkg -L "$pkg" | grep -m1 '/load\.bash$')"; \
        [ -n "$load" ] || { echo "no load.bash found in $pkg" >&2; exit 1; }; \
        ln -sfn "$(dirname "$load")" "/usr/local/lib/bats/$pkg"; \
    done; \
    ls -l /usr/local/lib/bats

# Tests use: bats_load_library bats-support
ENV BATS_LIB_PATH=/usr/local/lib/bats

# ── Pinned binaries not packaged by Debian ──────────────────────────────
# Renovate keeps these current.
#
#   task    runs this repo's taskfile.yml
#   yq      same tool the CI workflows use for YAML surgery
#   uv      provides pre-commit below, matches the repo's pyproject workflow
#   docker  client only, no daemon — points at the OrbStack VM via DOCKER_HOST
#   buildx  client-side plugin, needed for the multi-arch add-on builds
#   gh      GitHub CLI for PRs, CI runs and releases
#
# renovate: datasource=github-releases depName=go-task/task
ARG TASK_VERSION=v3.54.0
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=v4.53.6
# renovate: datasource=github-releases depName=astral-sh/uv
ARG UV_VERSION=0.12.23
# renovate: datasource=github-releases depName=moby/moby
ARG DOCKER_VERSION=29.8.0
# renovate: datasource=github-releases depName=docker/buildx
ARG BUILDX_VERSION=v0.37.0
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=v2.102.0

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        arm64) go_arch=arm64; uv_arch=aarch64-unknown-linux-gnu; docker_arch=aarch64 ;; \
        amd64) go_arch=amd64; uv_arch=x86_64-unknown-linux-gnu;  docker_arch=x86_64 ;; \
        *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    tmp="$(mktemp -d)"; \
    cd "$tmp"; \
    curl -fsSL -o task.tar.gz "https://github.com/go-task/task/releases/download/${TASK_VERSION}/task_linux_${go_arch}.tar.gz"; \
    tar -xzf task.tar.gz task; \
    install -m 0755 task /usr/local/bin/task; \
    curl -fsSL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${go_arch}"; \
    chmod 0755 /usr/local/bin/yq; \
    curl -fsSL -o uv.tar.gz "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${uv_arch}.tar.gz"; \
    tar -xzf uv.tar.gz; \
    install -m 0755 "uv-${uv_arch}/uv" /usr/local/bin/uv; \
    install -m 0755 "uv-${uv_arch}/uvx" /usr/local/bin/uvx; \
    curl -fsSL -o docker.tgz "https://download.docker.com/linux/static/stable/${docker_arch}/docker-${DOCKER_VERSION}.tgz"; \
    tar -xzf docker.tgz docker/docker; \
    install -m 0755 docker/docker /usr/local/bin/docker; \
    mkdir -p /usr/local/lib/docker/cli-plugins; \
    curl -fsSL -o /usr/local/lib/docker/cli-plugins/docker-buildx "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${go_arch}"; \
    chmod 0755 /usr/local/lib/docker/cli-plugins/docker-buildx; \
    gh_ver="${GH_VERSION#v}"; \
    curl -fsSL -o gh.tar.gz "https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${gh_ver}_linux_${go_arch}.tar.gz"; \
    tar -xzf gh.tar.gz "gh_${gh_ver}_linux_${go_arch}/bin/gh"; \
    install -m 0755 "gh_${gh_ver}_linux_${go_arch}/bin/gh" /usr/local/bin/gh; \
    cd /; \
    rm -rf "$tmp"

# pre-commit, installed into a world-readable prefix so the sandbox user can
# run it. The UV_TOOL_* vars are scoped to this RUN on purpose: leaking them
# into the runtime environment would point the unprivileged user's own
# `uv tool install` at a root-owned directory.
RUN set -eux; \
    UV_TOOL_DIR=/opt/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    uv tool install --no-cache pre-commit; \
    chmod -R a+rX /opt/uv; \
    pre-commit --version

# ── Sanity check: everything the tests rely on must be on PATH ──────────
RUN set -eux; \
    for t in bats shellcheck shfmt task yq uv uvx docker gh pre-commit; do \
        command -v "$t" >/dev/null || { echo "missing after build: $t" >&2; exit 1; }; \
    done; \
    python3 -c 'import yaml; print("pyyaml", yaml.__version__)'; \
    bats --version; \
    docker --version; \
    docker buildx version; \
    gh --version