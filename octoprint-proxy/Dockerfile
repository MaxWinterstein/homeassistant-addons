ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apk add haproxy

COPY run.sh haproxy.cfg /

RUN chmod a+x /run.sh
CMD [ "/run.sh" ]