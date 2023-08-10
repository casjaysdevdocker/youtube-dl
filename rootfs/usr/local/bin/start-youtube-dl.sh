#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202211131221-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  LICENSE.md
# @@ReadME           :  start-youtube-dl.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Sunday, Nov 13, 2022 12:21 EST
# @@File             :  start-youtube-dl.sh
# @@Description      :  script to start youtube-dl
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :  
# @@Resource         :  
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/start-service
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set functions
__curl() { curl -q -LSsf -o /dev/null "$@" &>/dev/null || return 10; }
__find() { find "$1" -mindepth 1 -type ${2:-f,d} 2>/dev/null | grep '^' || return 10; }
__pcheck() { [ -n "$(which pgrep 2>/dev/null)" ] && pgrep -x "$1" &>/dev/null || return 10; }
__pgrep() { __pcheck "$1" || ps aux 2>/dev/null | grep -Fw " $1" | grep -qv ' grep' || return 10; }
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
  __pgrep ${1:-} &>/dev/null || status=$((status + 1))
  #__curl "http://localhost:$SERVICE_PORT/server-health" || status=$((status + 1))
  [ "$status" -eq 0 ] || health="Errors reported see docker logs --follow $CONTAINER_NAME"
  return ${status:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__exec_command() {
  local exitCode=0
  local cmd="${*:-bash -l}"
  echo "Executing: $cmd"
  $cmd || exitCode=1
  [ "$exitCode" = 0 ] || exitCode=10
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set variables
DISPLAY="${DISPLAY:-}"
LANG="${LANG:-C.UTF-8}"
DOMAINNAME="${DOMAINNAME:-}"
TZ="${TZ:-America/New_York}"
SERVICE_PORT="${SERVICE_PORT:-$PORT}"
SERVICE_NAME="${CONTAINER_NAME:-}"
HOSTNAME="${HOSTNAME:-casjaysdev-youtube-dl}"
HOSTADMIN="${HOSTADMIN:-root@${DOMAINNAME:-$HOSTNAME}}"
SSL_CERT_BOT="${SSL_CERT_BOT:-false}"
SSL_ENABLED="${SSL_ENABLED:-false}"
SSL_DIR="${SSL_DIR:-/config/ssl}"
SSL_CA="${SSL_CA:-$SSL_DIR/ca.crt}"
SSL_KEY="${SSL_KEY:-$SSL_DIR/server.key}"
SSL_CERT="${SSL_CERT:-$SSL_DIR/server.crt}"
SSL_CONTAINER_DIR="${SSL_CONTAINER_DIR:-/etc/ssl/CA}"
WWW_ROOT_DIR="${WWW_ROOT_DIR:-/data/htdocs}"
LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-/usr/local/bin}"
DATA_DIR_INITIALIZED="${DATA_DIR_INITIALIZED:-}"
CONFIG_DIR_INITIALIZED="${CONFIG_DIR_INITIALIZED:-}"
DEFAULT_DATA_DIR="${DEFAULT_DATA_DIR:-/usr/local/share/template-files/data}"
DEFAULT_CONF_DIR="${DEFAULT_CONF_DIR:-/usr/local/share/template-files/config}"
DEFAULT_TEMPLATE_DIR="${DEFAULT_TEMPLATE_DIR:-/usr/local/share/template-files/defaults}"
CONTAINER_IP_ADDRESS="$(ip a 2>/dev/null | grep 'inet' | grep -v '127.0.0.1' | awk '{print $2}' | sed 's|/.*||g')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Overwrite variables
#SERVICE_PORT=""
SERVICE_NAME="youtube-dl"
SERVICE_COMMAND="$SERVICE_NAME"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show start message
start_message="Starting $SERVICE_NAME on $CONTAINER_IP_ADDRESS:$SERVICE_PORT"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$SERVICE_PORT" = "443" ] && SSL_ENABLED="true"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Pre copy commands

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check if this is a new container
[ -z "$DATA_DIR_INITIALIZED" ] && [ -f "/data/.docker_has_run" ] && DATA_DIR_INITIALIZED="true"
[ -z "$CONFIG_DIR_INITIALIZED" ] && [ -f "/config/.docker_has_run" ] && CONFIG_DIR_INITIALIZED="true"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create default config
if [ "$CONFIG_DIR_INITIALIZED" = "false" ] && [ -n "$DEFAULT_TEMPLATE_DIR" ]; then
  [ -d "/config" ] && cp -Rf "$DEFAULT_TEMPLATE_DIR/." "/config/" 2>/dev/null
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy custom config files
if [ "$CONFIG_DIR_INITIALIZED" = "false" ] && [ -n "$DEFAULT_CONF_DIR" ]; then
  [ -d "/config" ] && cp -Rf "$DEFAULT_CONF_DIR/." "/config/" 2>/dev/null
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy custom data files
if [ "$DATA_DIR_INITIALIZED" = "false" ] && [ -n "$DEFAULT_DATA_DIR" ]; then
  [ -d "/data" ] && cp -Rf "$DEFAULT_DATA_DIR/." "/data/" 2>/dev/null
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy html files
if [ "$DATA_DIR_INITIALIZED" = "false" ] && [ -d "$DEFAULT_DATA_DIR/data/htdocs" ]; then
  [ -d "/data" ] && cp -Rf "$DEFAULT_DATA_DIR/data/htdocs/." "$WWW_ROOT_DIR/" 2>/dev/null
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Post copy commands

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initialized
[ -d "/data" ] && touch "/data/.docker_has_run"
[ -d "/config" ] && touch "/config/.docker_has_run"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# APP Variables overrides
[ -f "/root/env.sh" ] && . "/root/env.sh"
[ -f "/config/env.sh" ] && . "/config/env.sh"
[ -f "/config/.env.sh" ] && . "/config/.env.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Actions based on env

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# begin main app
case "$1" in
healthcheck)
  shift 1
  __heath_check "${SERVICE_NAME:-bash}"
  exit $?
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

*)
  if __pgrep "$SERVICE_NAME" && [ ! -f "/tmp/$SERVICE_NAME.pid" ]; then
    echo "$SERVICE_NAME is running"
  else
    touch "/tmp/$SERVICE_NAME.pid"
    echo "$start_message"
    __exec_command "$SERVICE_COMMAND" || rm -Rf "/tmp/$SERVICE_NAME.pid"
  fi
  ;;
esac
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set exit code
exitCode="${exitCode:-$?}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# lets exit with code
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# end
# ex: ts=2 sw=2 et filetype=sh
