ARG BUILD_FROM=ghcr.io/hassio-addons/base-python/amd64:15.0.1
FROM ${BUILD_FROM}

# add source and unpack
ADD "https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/archive/refs/tags/v2.5.1.tar.gz" /src.tar.gz
RUN mkdir /app && tar xvfz /src.tar.gz -C /app --strip-components=1

# install
WORKDIR /app
RUN pip install -r requirements.txt
RUN python setup.py install

ADD rootfs /

# Corrects permissions for s6 v3
RUN if [ -d /etc/cont-init.d ]; then chmod -R 755 /etc/cont-init.d; fi && \
    if [ -d /etc/services.d ]; then chmod -R 755 /etc/services.d; fi && \
    if [ -f /entrypoint.sh ]; then chmod 755 /entrypoint.sh; fi
