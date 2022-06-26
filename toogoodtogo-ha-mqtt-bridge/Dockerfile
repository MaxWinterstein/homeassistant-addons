ARG BUILD_FROM=ghcr.io/hassio-addons/base-python/amd64:6.0.0
FROM ${BUILD_FROM}

# add source and unpack
ADD "https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/archive/v2.3.0.tar.gz" /src.tar.gz
RUN mkdir /app && tar xvfz /src.tar.gz -C /app --strip-components=1

# install
WORKDIR /app
RUN pip install -r requirements.txt
RUN python setup.py install

ADD rootfs /