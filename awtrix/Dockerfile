ARG BUILD_FROM
FROM $BUILD_FROM

WORKDIR /data

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apk add --no-cache openjdk8 wget nginx

COPY rootfs /

ADD https://blueforcer.de/awtrix/stable/awtrix.jar /stable.jar

# Labels
LABEL \
    io.hass.name="Awtrix_host" \
    io.hass.description="Server for the awtrix-8x32 RGB display." \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION}

