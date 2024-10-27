ARG BUILD_FROM=ghcr.io/hassio-addons/base:16.3.4
FROM $BUILD_FROM

ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000
ENV S6_KEEP_ENV=1

RUN apk add nginx inotify-tools

RUN rm /etc/nginx/http.d/default.conf

COPY root /

RUN ln -s /octoprint /config

# RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log