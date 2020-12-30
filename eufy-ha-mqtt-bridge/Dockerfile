FROM matijse/eufy-ha-mqtt-bridge

RUN apt-get update && apt-get install -y jq sqlite3
RUN npm install json2yaml

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
