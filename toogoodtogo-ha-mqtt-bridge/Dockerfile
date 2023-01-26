ARG BUILD_FROM=ghcr.io/hassio-addons/base-python/amd64:9.0.1
FROM ${BUILD_FROM}

# add source and unpack
ADD "https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/archive/refs/tags/v2.5.1.tar.gz" /src.tar.gz
RUN mkdir /app && tar xvfz /src.tar.gz -C /app --strip-components=1

# install
WORKDIR /app
RUN pip install -r requirements.txt
RUN python setup.py install

ADD rootfs /