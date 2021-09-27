ARG BUILD_FROM=ghcr.io/hassio-addons/ubuntu-base/amd64:6.0.0
FROM $BUILD_FROM

ADD feed-dl /feed-dl 

RUN apt-get update && apt-get -y upgrade && \
    apt-get -y install procps librtlsdr0 librtlsdr-dev wget unzip build-essential pkg-config ca-certificates && \
    wget https://github.com/MalcolmRobb/dump1090/archive/master.zip && \
    unzip master.zip && \
    rm master.zip && \
    cd dump1090-master && \
    make && \
    cp -a dump1090 view1090 public_html /bin && \
    cd / && \
    rm -r /dump1090-master && \
    '.' '/feed-dl' && \
     rm /feed-dl && \
    apt-get -y purge librtlsdr-dev wget unzip build-essential pkg-config && \
    apt-get --purge -y autoremove && \
    apt-get clean && \
    rm -r /var/lib/apt/lists/* 

ADD fr24feed.ini /etc/fr24feed.ini

EXPOSE 8080 8754 30001-30005

ENTRYPOINT ["fr24feed"]
CMD [ "--fr24key=B795E67A93A81C36" ]