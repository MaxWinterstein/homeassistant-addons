ARG BUILD_FROM
FROM $BUILD_FROM

# Set the Angry IP Scanner version as a variable
# renovate: datasource=github-releases depName=angryip/ipscan versioning=semver
ARG IP_SCAN_VERSION=3.9.1

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Angry IP Scanner dependencies
RUN \
    set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        iproute2 \
        iputils-ping \
        nginx \
        novnc \
        sqlite3 \
        tigervnc-common \
        tigervnc-standalone-server \
        wget \
        wmii \
        xfonts-base \
        xfonts-scalable \
        openjdk-11-jre \
        libswt-cairo-gtk-4-jni \
        libswt-gtk-4-java \
    && rm -rf /var/lib/apt/lists/*

# Download and install Angry IP Scanner
RUN wget https://github.com/angryip/ipscan/releases/download/${IP_SCAN_VERSION}/ipscan_${IP_SCAN_VERSION}_all.deb && \
        dpkg -i ipscan_${IP_SCAN_VERSION}_all.deb

COPY rootfs /

# Fix missing permissions - not really sure why this is needed
RUN chmod +x /etc/cont-init.d/nginx.sh /etc/cont-init.d/novnc.sh
RUN chmod 777 /etc/services.d/*/*
