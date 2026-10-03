ARG BUILD_FROM
FROM $BUILD_FROM

# The add-on version mirrors this: 4.<CUPS upstream version>, e.g. 4.2.4.2 for 2.4.2
ARG CUPS_VERSION=2.4.2-3+deb12u9

LABEL io.hass.version="1.0" io.hass.type="addon" io.hass.arch="aarch64|amd64"

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cups=${CUPS_VERSION} \
        sudo \
        locales \
        avahi-daemon \
        libnss-mdns \
        dbus \
        colord \
        printer-driver-all-enforce \
        openprinting-ppds \
        hpijs-ppds \
        hp-ppd \
        hplip \
        cups-pdf \
        gnupg2 \
        lsb-release \
        nano \
        samba \
        smbclient \
        bash-completion \
        procps \
        whois \
        curl \
        bc \
        jq \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

COPY rootfs /

# Add user and disable sudo password checking
RUN useradd \
    --groups=sudo,lp,lpadmin \
    --create-home \
    --home-dir=/home/print \
    --shell=/bin/bash \
    --password=$(mkpasswd print) \
    print \
    && sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

EXPOSE 631

RUN chmod a+x /run.sh

CMD ["/run.sh"]