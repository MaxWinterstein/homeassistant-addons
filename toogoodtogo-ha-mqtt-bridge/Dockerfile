ARG BUILD_FROM=ghcr.io/hassio-addons/base-python/amd64:6.0.0
FROM ${BUILD_FROM}

# Add poetry # TODO: Get rid of the overhead
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
ENV PATH=$HOME/.poetry/bin/:${PATH}
RUN poetry config virtualenvs.create false

# add source and unpack
ADD "https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge/archive/v1.5.0.tar.gz" /src.tar.gz
RUN mkdir /app && tar xvfz /src.tar.gz -C /app --strip-components=1

# install
WORKDIR /app
RUN poetry install --no-dev

COPY run.sh /
RUN chmod a+x /run.sh
ENV DYNACONF_DATA_DIR=/data
CMD [ "/run.sh" ]
