FROM hassioaddons/debian-base

ENV LANG C.UTF-8

# install node and build tools (needed by node-pre-gy)
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && apt install -y nodejs g++ make python

# ass source and unpack
RUN mkdir /src /app && curl -sL https://github.com/matijse/eufy-ha-mqtt-bridge/tarball/main | tar xvfz - -C /app --strip-components=1

# install all (and json2yaml for Cofiguration parsing)
WORKDIR /app
RUN npm install && npm install -g json2yaml

COPY run.sh /
RUN chmod a+x /run.sh
CMD [ "/run.sh" ]
