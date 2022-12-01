ARG BUILD_FROM
FROM $BUILD_FROM

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
        openjdk-11-jre libswt-cairo-gtk-4-jni libswt-gtk-4-java\
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/angryip/ipscan/releases/download/3.8.2/ipscan_3.8.2_all.deb && \
        dpkg -i ipscan_3.8.2_all.deb

COPY rootfs /

# Fix missing permissions - not really sure why this is needed
RUN chmod +x /etc/cont-init.d/nginx.sh /etc/cont-init.d/novnc.sh
RUN chmod 777 /etc/services.d/*/*
