ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-python:3.12-alpine3.20
FROM ${BUILD_FROM}

# install uv
# renovate: datasource=github-releases depName=uv packageName=astral-sh/uv
ENV UV_VERSION="0.7.20"
RUN pip install uv==$UV_VERSION

# add source and unpack
# renovate: datasource=github-releases depName=toogoodtogo-ha-mqtt-bridge packageName=MaxWinterstein/toogoodtogo-ha-mqtt-bridge
ARG TOOGOODTOGO_VERSION=3.5.0
ADD "https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/archive/refs/tags/v${TOOGOODTOGO_VERSION}.tar.gz" /src.tar.gz
RUN mkdir /app && tar xvfz /src.tar.gz -C /app --strip-components=1
# as we want no full blown git checkout, but some nice version, we use the lazy man setuptools_scm env var
ENV SETUPTOOLS_SCM_PRETEND_VERSION=${TOOGOODTOGO_VERSION}

# install
WORKDIR /app

# Install dependencies
RUN uv sync --frozen --no-dev --index-strategy unsafe-best-match
# install all the other stuff
ADD rootfs /


# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# Poor mans test if at least the imports work
RUN python toogoodtogo_ha_mqtt_bridge/main.py --version

# Corrects permissions for s6 v3
RUN if [ -d /etc/cont-init.d ]; then chmod -R 755 /etc/cont-init.d; fi && \
    if [ -d /etc/services.d ]; then chmod -R 755 /etc/services.d; fi && \
    if [ -f /entrypoint.sh ]; then chmod 755 /entrypoint.sh; fi
