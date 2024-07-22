ARG BUILD_FROM=buanet/iobroker:v9.1.2
FROM ${BUILD_FROM}

# copy over the patched iobroker_startup.sh
COPY iobroker_startup.sh /opt/scripts/iobroker_startup.sh
RUN chmod a+x /opt/scripts/iobroker_startup.sh
