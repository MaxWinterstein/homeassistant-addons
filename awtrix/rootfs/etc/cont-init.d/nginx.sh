#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: grafana
# Configures NGINX
# ==============================================================================
declare ingress_entry
declare ingress_interface

bashio::log.info "Configuring NGINX"

ingress_interface=$(bashio::addon.ip_address)
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/services.d/nginx/run

ingress_entry=$(bashio::addon.ingress_entry)
sed -i "s#%%ingress_entry%%#${ingress_entry}#g" /etc/nginx/servers/ingress.conf


