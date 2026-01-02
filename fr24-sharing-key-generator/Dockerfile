ARG BUILD_FROM=thomx/fr24feed-piaware:2.6.0
FROM $BUILD_FROM

# Install expect
RUN apt-get update \
    && apt-get install -y expect jq \
    && rm -rf /var/lib/apt/lists/*

# Set ENV variables for signup
ENV FR24_EMAIL="you@example.com"
ENV FR24_KEY=""
ENV FR24_MLAT="no"
ENV FR24_LAT="50.1234"
ENV FR24_LON="8.1234"
ENV FR24_ALT="123"
ENV FR24_CONFIRM_SETTINGS="yes"
ENV FR24_AUTOCONFIG="no"
ENV FR24_RECV_TYPE="1"
ENV FR24_RAW_FEED=""
ENV FR24_BASE_FEED="no"

# Add the expect script
COPY signup.exp /signup.exp
RUN chmod +x /signup.exp

# Add nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Add entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]