FROM thomx/fr24feed-piaware:1.7.0

# add bashio (thx https://github.com/hassio-addons/addon-debian-base/blob/main/base/Dockerfile#L47)
ADD https://github.com/hassio-addons/bashio/archive/v0.13.0.tar.gz  /tmp/bashio.tar.gz
RUN apt-get update && apt-get install -y curl jq && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio

# add the options.json to environment variable magic
COPY export-env-from-config.sh /export-env-from-config.sh

RUN find /etc/services.d/ -name run | xargs sed -i '1 a\source /export-env-from-config.sh' && \
    find /etc/cont-init.d/ -type f | xargs sed -i '1 a\source /export-env-from-config.sh'

ENV TZ=UTC

# Add the nice banner
ADD https://raw.githubusercontent.com/hassio-addons/addon-debian-base/v5.1.0/base/rootfs/etc/cont-init.d/00-banner.sh /etc/cont-init.d/
