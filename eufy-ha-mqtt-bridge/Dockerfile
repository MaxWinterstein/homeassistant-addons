FROM hassioaddons/debian-base
ENV LANG C.UTF-8

# install node and build tools (needed by node-pre-gy)
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && apt install -y nodejs g++ make python

# Calls for a random number to break the cache
# (https://stackoverflow.com/questions/35134713/disable-cache-for-specific-run-commands/58801213#58801213)
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache

# add source and unpack
ADD "https://github.com/matijse/eufy-ha-mqtt-bridge/tarball/main" /src.tar.gz
RUN mkdir /app && tar xvfz /src.tar.gz -C /app --strip-components=1

# install all (and json2yaml for Cofiguration parsing)
WORKDIR /app
RUN npm install && npm install -g json2yaml

COPY run.sh /
RUN chmod a+x /run.sh
CMD [ "/run.sh" ]
