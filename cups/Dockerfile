ARG BUILD_FROM
FROM $BUILD_FROM

LABEL io.hass.version="1" io.hass.type="addon" io.hass.arch="armhf|aarch64|i386|amd64"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cups \
        avahi-daemon \
        libnss-mdns \
        dbus \
        colord \
        printer-driver-all \
        printer-driver-gutenprint \
        openprinting-ppds \
        hpijs-ppds \
        hp-ppd  \
        hplip \
        printer-driver-foo2zjs \
        gnupg2 \
        lsb-release \
        nano \
        samba \
        bash-completion \
        nginx \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

COPY rootfs /

EXPOSE 631 445 137 139

CMD ["/run.sh"]
