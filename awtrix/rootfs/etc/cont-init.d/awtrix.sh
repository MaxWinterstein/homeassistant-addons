#!/usr/bin/with-contenv bashio

runfolder="/data"
datafolder="/config"

bashio::log.info "Addon Version 0.2.6 (Awtrix 2.0 beta)"

if bashio::fs.directory_exists "${datafolder}"; then
    if ! bashio::fs.directory_exists "${datafolder}/awtrix"; then
      mkdir "${datafolder}/awtrix"
      bashio::log.info "mkdir /config/awtrix"
    fi
    if ! bashio::fs.directory_exists "${datafolder}/awtrix/config"; then
      mkdir "${datafolder}/awtrix/config"
      bashio::log.info "mkdir /config/awtrix/config"
    fi   
    if ! bashio::fs.directory_exists "${datafolder}/awtrix/apps"; then
      mkdir "${datafolder}/awtrix/apps"
      bashio::log.info "mkdir /config/awtrix/apps"
    fi
    if ! bashio::fs.directory_exists "${runfolder}/Apps"; then
      ln -s "${datafolder}/awtrix/apps" "${runfolder}/Apps"
      bashio::log.info "ln -s Apps"
    fi
    if ! bashio::fs.directory_exists "${runfolder}/config"; then
      ln -s "${datafolder}/awtrix/config" "${runfolder}/config"
      bashio::log.info "ln -s" "${datafolder}/awtrix/config" "${runfolder}/config"
    fi
else
  bashio::log.error "No /config folder"
  exit 
fi

if bashio::config.exists 'lang'; then
    lang=$(bashio::config 'lang')
    bashio::log.info "Setting lang to ${lang}..."
    export LANG=${lang}
fi

cd $runfolder

version=$(bashio::config 'version')

bashio::log.warning "disabling hassio-detection"
export SUPERVISOR_TOKEN=-1

bashio::log.info "Starting awtrix (${version})..."

exec /usr/bin/java -jar /$version.jar --logger=stdout &



