ARG BUILD_FROM
FROM $BUILD_FROM

ARG VERSION=0.2.24

RUN apk add --no-cache nodejs npm make g++

# add source and unpack
ADD "https://github.com/matijse/eufy-ha-mqtt-bridge/archive/${VERSION}.tar.gz" /src.tar.gz
RUN mkdir /app && tar xvfz /src.tar.gz -C /app --strip-components=1

# install all (and json2yaml for cofiguration parsing)
WORKDIR /app
RUN npm install && npm install -g json2yaml && echo ${VERSION} > /version

COPY run.sh /
RUN chmod a+x /run.sh
CMD [ "/run.sh" ]
