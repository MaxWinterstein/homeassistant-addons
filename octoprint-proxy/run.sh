#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "Setting octoprint host: $(bashio::config octoprint_host)"
sed -i "s/OCTOPRINT_HOST/$(bashio::config octoprint_host)/g" /haproxy.cfg

bashio::log.info "Setting octoprint port: $(bashio::config octoprint_port)"
sed -i "s/OCTOPRINT_PORT/$(bashio::config octoprint_port)/g" /haproxy.cfg

if $(bashio::config.true ssl.enabled); then
	bashio::log.info "SSL communitcation to octoprint enabled"
	sed -i "s/USE_SSL/ssl/g" /haproxy.cfg

	if $(bashio::config.true ssl.verify); then
		bashio::log.info "SSL verification enabled"
		sed -i "s/VERIFY_SSL//g" /haproxy.cfg
	else
		bashio::log.info "SSL verification disabled"
		sed -i "s/VERIFY_SSL/verify none/g" /haproxy.cfg
	fi

else
	bashio::log.info "SSL communitcation to octoprint not enabled"
	sed -i "s/USE_SSL VERIFY_SSL//g" /haproxy.cfg
fi

bashio::log.info "Server line: $(cat /haproxy.cfg | grep 'server octoprint')"

bashio::log.info "Starting haproxy"
haproxy -W -db -f /haproxy.cfg
