FROM matijse/eufy-ha-mqtt-bridge

RUN npm install json2yaml

COPY docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
