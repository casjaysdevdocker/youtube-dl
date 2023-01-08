#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202211131221-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.com
# @@License          :  LICENSE.md
# @@ReadME           :  entrypoint.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Sunday, Nov 13, 2022 12:21 EST
# @@File             :  entrypoint.sh
# @@Description      :  entrypoint point for youtube-dl
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :  
# @@Resource         :  
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/docker-entrypoint
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
[ -n "$DEBUG" ] && set -x
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set functions
__exec_command() {
  local exitCode=0
  local cmd="${*:-bash -l}"
  echo "${exec_message:-Executing command: $cmd}"
  $cmd || exitCode=1
  [ "$exitCode" = 0 ] || exitCode=10
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__curl() { curl -q -LSsf -o /dev/null "$@" &>/dev/null || return 10; }
__find() { find "$1" -mindepth 1 -type ${2:-f,d} 2>/dev/null | grep '^' || return 10; }
__pcheck() { [ -n "$(which pgrep 2>/dev/null)" ] && pgrep -x "$1" &>/dev/null || return 10; }
__pgrep() { __pcheck "${1:-$SERVICE_NAME}" || ps aux 2>/dev/null | grep -Fw " ${1:-$SERVICE_NAME}" | grep -qv ' grep' || return 10; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__certbot() {
  [ -n "$DOMAINNAME" ] && [ -n "$CERT_BOT_MAIL" ] || { echo "The variables DOMAINNAME and CERT_BOT_MAIL are set" && exit 1; }
  [ "$SSL_CERT_BOT" = "true" ] && type -P certbot &>/dev/null || { export SSL_CERT_BOT="" && return 10; }
  certbot $1 --agree-tos -m $CERT_BOT_MAIL certonly --webroot -w "${WWW_ROOT_DIR:-/data/htdocs/www}" -d $DOMAINNAME -d $DOMAINNAME \
    --put-all-related-files-into "$SSL_DIR" -key-path "$SSL_KEY" -fullchain-path "$SSL_CERT"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__heath_check() {
  status=0 health="Good"
  start-youtube-dl.sh healthcheck || status=$((status + 1))
  [ "$status" -eq 0 ] || health="Errors reported see docker logs --follow $CONTAINER_NAME"
  echo "$(uname -s) $(uname -m) is running and the health is: $health"
  return ${status:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__start_all_services() {
  echo "$service_message"
  start-youtube-dl.sh
  return $?
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional functions

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# export functions
export -f __exec_command __pcheck __pgrep __find __curl __heath_check __certbot __start_all_services
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define default variables - do not change these - redefine with -e or set under Additional
DISPLAY="${DISPLAY:-}"
LANG="${LANG:-C.UTF-8}"
DOMAINNAME="${DOMAINNAME:-}"
TZ="${TZ:-America/New_York}"
SERVICE_PORT="${SERVICE_PORT:-$PORT}"
HOSTNAME="${HOSTNAME:-casjaysdev-youtube-dl}"
HOSTADMIN="${HOSTADMIN:-root@${DOMAINNAME:-$HOSTNAME}}"
CERT_BOT_MAIL="${CERT_BOT_MAIL:-certbot-mail@casjay.net}"
SSL_CERT_BOT="${SSL_CERT_BOT:-false}"
SSL_ENABLED="${SSL_ENABLED:-false}"
SSL_DIR="${SSL_DIR:-/config/ssl}"
SSL_CA="${SSL_CA:-$SSL_DIR/ca.crt}"
SSL_KEY="${SSL_KEY:-$SSL_DIR/server.key}"
SSL_CERT="${SSL_CERT:-$SSL_DIR/server.crt}"
SSL_CONTAINER_DIR="${SSL_CONTAINER_DIR:-/etc/ssl/CA}"
WWW_ROOT_DIR="${WWW_ROOT_DIR:-/data/htdocs}"
LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-/usr/local/bin}"
DEFAULT_DATA_DIR="${DEFAULT_DATA_DIR:-/usr/local/share/template-files/data}"
DEFAULT_CONF_DIR="${DEFAULT_CONF_DIR:-/usr/local/share/template-files/config}"
DEFAULT_TEMPLATE_DIR="${DEFAULT_TEMPLATE_DIR:-/usr/local/share/template-files/defaults}"
CONTAINER_IP_ADDRESS="$(ip a 2>/dev/null | grep 'inet' | grep -v '127.0.0.1' | awk '{print $2}' | sed 's|/.*||g')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional variables and variable overrides
SERVICE_NAME="youtube-dl"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show start message
export service_message="Starting $CONTAINER_NAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$SERVICE_PORT" = "443" ] && SSL_ENABLED="true"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check if this is a new container
[ -f "/data/.docker_has_run" ] && DATA_DIR_INITIALIZED="true" || DATA_DIR_INITIALIZED="false"
[ -f "/config/.docker_has_run" ] && CONFIG_DIR_INITIALIZED="true" || CONFIG_DIR_INITIALIZED="false"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# export variables
export LANG TZ DOMAINNAME HOSTNAME HOSTADMIN SSL_ENABLED SSL_DIR SSL_CA SSL_KEY SERVICE_NAME
export SSL_DIR LOCAL_BIN_DIR DEFAULT_CONF_DIR CONTAINER_IP_ADDRESS SSL_CONTAINER_DIR
export SSL_CERT_BOT DISPLAY CONFIG_DIR_INITIALIZED DATA_DIR_INITIALIZED
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import variables from file
[ -f "/root/env.sh" ] && . "/root/env.sh"
[ -f "/config/env.sh" ] && . "/config/env.sh"
[ -f "/config/.env.sh" ] && . "/config/.env.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set timezone
[ -n "$TZ" ] && echo "$TZ" >"/etc/timezone"
[ -f "/usr/share/zoneinfo/$TZ" ] && ln -sf "/usr/share/zoneinfo/$TZ" "/etc/localtime"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set hostname
if [ -n "$HOSTNAME" ]; then
  echo "$HOSTNAME" >"/etc/hostname"
  echo "127.0.0.1 $HOSTNAME localhost $HOSTNAME.local" >"/etc/hosts"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Add domain to hosts file
if [ -n "$DOMAINNAME" ]; then
  echo "$HOSTNAME.${DOMAINNAME:-local}" >"/etc/hostname"
  echo "127.0.0.1 $HOSTNAME localhost $HOSTNAME.local" >"/etc/hosts"
  echo "${CONTAINER_IP_ADDRESS:-127.0.0.1} $HOSTNAME.$DOMAINNAME" >>"/etc/hosts"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Delete any gitkeep files
[ -d "/data" ] && rm -Rf "/data/.gitkeep" "/data"/*/*.gitkeep
[ -d "/config" ] && rm -Rf "/config/.gitkeep" "/data"/*/*.gitkeep
[ -f "/usr/local/bin/.gitkeep" ] && rm -Rf "/usr/local/bin/.gitkeep"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create directories
[ -d "/etc/ssl" ] || mkdir -p "$SSL_CONTAINER_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create files

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create symlinks

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "$SSL_ENABLED" = "true" ] || [ "$SSL_ENABLED" = "yes" ]; then
  if [ -f "/config/ssl/server.crt" ] && [ -f "/config/ssl/server.key" ]; then
    export SSL_ENABLED="true"
    if [ -n "$SSL_CA" ] && [ -f "$SSL_CA" ]; then
      mkdir -p "$SSL_CONTAINER_DIR/certs"
      cat "$SSL_CA" >>"/etc/ssl/certs/ca-certificates.crt"
      cp -Rf "/config/ssl/." "$SSL_CONTAINER_DIR/"
    fi
  else
    [ -d "$SSL_DIR" ] || mkdir -p "$SSL_DIR"
    create-ssl-cert
  fi
  type update-ca-certificates &>/dev/null && update-ca-certificates
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "$SSL_CA" ] && cp -Rfv "$SSL_CA" "$SSL_CONTAINER_DIR/ca.crt"
[ -f "$SSL_KEY" ] && cp -Rfv "$SSL_KEY" "$SSL_CONTAINER_DIR/server.key"
[ -f "$SSL_CERT" ] && cp -Rfv "$SSL_CERT" "$SSL_CONTAINER_DIR/server.crt"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup bin directory
SET_USR_BIN=""
[ -d "/data/bin" ] && SET_USR_BIN+="$(__find /data/bin f) "
[ -d "/config/bin" ] && SET_USR_BIN+="$(__find /config/bin f) "
if [ -n "$SET_USR_BIN" ]; then
  echo "Setting up bin"
  for create_bin in $SET_USR_BIN; do
    if [ -n "$create_bin" ]; then
      create_bin_name="$(basename "$create_bin")"
      ln -sf "$create_bin" "$LOCAL_BIN_DIR/$create_bin_name"
    fi
  done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create default config
if [ "$CONFIG_DIR_INITIALIZED" = "false" ] && [ -d "/config" ]; then
  echo "Copying default config files"
  if [ -n "$DEFAULT_TEMPLATE_DIR" ] && [ -d "$DEFAULT_TEMPLATE_DIR" ]; then
    for create_template in "$DEFAULT_TEMPLATE_DIR"/*; do
      create_template_name="$(basename "$create_template")"
      if [ -n "$create_template" ]; then
        if [ -d "$create_template" ]; then
          mkdir -p "/config/$create_template_name/"
          cp -Rf "$create_template/." "/config/$create_template_name/" 2>/dev/null
        else
          cp -Rf "$create_template" "/config/$create_template_name" 2>/dev/null
        fi
      fi
    done
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy custom config files
if [ "$CONFIG_DIR_INITIALIZED" = "false" ] && [ -d "/config" ]; then
  echo "Copying custom config files"
  for create_config in "$DEFAULT_CONF_DIR"/*; do
    create_config_name="$(basename "$create_config")"
    if [ -n "$create_config" ]; then
      if [ -d "$create_config" ]; then
        mkdir -p "/config/$create_config_name"
        cp -Rf "$create_config/." "/config/$create_config_name/" 2>/dev/null
      else
        cp -Rf "$create_config" "/config/$create_config_name" 2>/dev/null
      fi
    fi
  done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy custom data files
if [ "$DATA_DIR_INITIALIZED" = "false" ] && [ -d "/data" ]; then
  echo "Copying data files"
  for create_data in "$DEFAULT_DATA_DIR"/*; do
    create_data_name="$(basename "$create_data")"
    if [ -n "$create_data" ]; then
      if [ -d "$create_data" ]; then
        mkdir -p "/data/$create_data_name"
        cp -Rf "$create_data/." "/data/$create_data_name/" 2>/dev/null
      else
        cp -Rf "$create_data" "/data/$create_data_name" 2>/dev/null
      fi
    fi
  done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy /config to /etc
if [ -d "/config" ]; then
  [ "$CONFIG_DIR_INITIALIZED" = "false" ] && echo "Copying /config to /etc"
  for create_conf in /config/*; do
    if [ -n "$create_conf" ]; then
      create_conf_name="$(basename "$create_conf")"
      if [ -e "/etc/$create_conf_name" ]; then
        if [ -d "/etc/$create_conf_name" ]; then
          mkdir -p "/etc/$create_conf_name/"
          cp -Rf "$create_conf/." "/etc/$create_conf_name/" 2>/dev/null
        else
          cp -Rf "$create_conf" "/etc/$create_conf_name" 2>/dev/null
        fi
      fi
    fi
  done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Unset unneeded variables
unset SET_USR_BIN create_bin create_bin_name create_template create_template_name
unset create_data create_data_name create_config create_config_name create_conf create_conf_name
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "/data/.docker_has_run" ] || { [ -d "/data" ] && echo "Initialized on: $(date)" >"/data/.docker_has_run"; }
[ -f "/config/.docker_has_run" ] || { [ -d "/config" ] && echo "Initialized on: $(date)" >"/config/.docker_has_run"; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional commands

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show message
echo "Container ip address is: $CONTAINER_IP_ADDRESS"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
case "$1" in
--help) # Help message
  echo 'Docker container for '$APPNAME''
  echo "Usage: $APPNAME [healthcheck, bash, command]"
  echo "Failed command will have exit code 10"
  echo ""
  exit ${exitCode:-$?}
  ;;

healthcheck) # Docker healthcheck
  __heath_check "${1:-$SERVICE_NAME}" || exitCode=10
  exit ${exitCode:-$?}
  ;;

*/bin/sh | */bin/bash | bash | shell | sh) # Launch shell
  shift 1
  __exec_command "${@:-/bin/bash}"
  exit ${exitCode:-$?}
  ;;

certbot)
  shift 1
  SSL_CERT_BOT="true"
  if [ "$1" = "create" ]; then
    shift 1
    __certbot
  elif [ "$1" = "renew" ]; then
    shift 1
    __certbot "renew certonly --force-renew"
  else
    __exec_command "certbot" "$@"
  fi
  ;;

*) # Execute primary command
  if [ $# -eq 0 ]; then
    __start_all_services
    exit ${exitCode:-$?}
  else
    __exec_command "$@"
    exitCode=$?
  fi
  ;;
esac
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# end of entrypoint
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# ex: ts=2 sw=2 et filetype=sh
