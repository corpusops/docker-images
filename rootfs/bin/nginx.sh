#!/usr/bin/env sh
set -e
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
NO_CHOWN=${NO_CHOWN-}
export NGINX_CONF_DIR="${NGINX_CONF_DIR:-"/etc/nginx"}"
# French legal http logs retention  is 3 years
export NO_SSL=${NO_SSL-1}
export SSL_CERT_BASENAME="${SSL_CERT_BASENAME:-"cert"}"
export NGINX_SKIP_CHECK="${NGINX_SKIP_CHECK-}"
export NGINX_ROTATE=${NGINX_ROTATE-$((365*3))}
export NGINX_USER=${NGINX_USER-"nginx"}
export NGINX_GROUP=${NGINX_GROUP-"nginx"}
export NGINX_STD_OUTPUT=${NGINX_STD_OUTPUT-}
export NGINX_RUN_DIR="${NGINX_RUN_DIR:-"/var/run"}"
export NGINX_PIDFILE="${NGINX_PIDFILE:-"${NGINX_RUN_DIR}/nginx.pid"}"
export NGINX_LOGS_DIR="${NGINX_LOGS_DIR:-"/var/log/nginx"}"
export NGINX_LOGS_DIRS="/logs /log $NGINX_LOGS_DIR"
export NGINX_SOCKET_DIR="$(dirname "$NGINX_SOCKET_PATH")"
export NGINX_BIN=${NGINX_BIN:-"nginx"}
export NGINX_FREP_SKIP=${NGINX_FREP_SKIP:-"(\.skip|\.skipped)$"}
export NGINX_CONFIGS="${NGINX_CONFIGS-"$( \
    find $NGINX_CONF_DIR -type f \
    |egrep -v "$NGINX_FREP_SKIP|\.template$")
/etc/logrotate.d/nginx"}"
log() { echo "$@" >&2; }
vv() { log "$@";"$@"; }
if [ "x$NGINX_STD_OUTPUT" = "x" ];then rm -fv $NGINX_LOGS_DIR/*;fi
for e in $NGINX_LOGS_DIRS $NGINX_CONF_DIR;do
    if [ ! -e "$e" ];then mkdir -p "$e";fi
    if [ "x$NO_CHOWN" != "x" ] && [ -e "$e" ];then chown "$NGINX_USER" "$e";fi
done
for i in $NGINX_CONFIGS;do frep $i:$i --overwrite;done
DEFAULT_NGINX_DH_FILE="/certs/dhparams.pem"
if [ "x$NGINX_CONFIGS" != "x" ];then
    if ! (egrep -r -q "\s*ssl_dhparam" $NGINX_CONFIGS);then
        DEFAULT_NGINX_DH_FILE=""
    fi
fi
export NGINX_DH_FILE=${NGINX_DH_FILE:-"$DEFAULT_NGINX_DH_FILE"}
chmod 600 /etc/logrotate.d/nginx
if [ "x$NO_SSL" = "x1" ];then
    log "no ssl setup"
else
    cops_gen_cert.sh
    if !(openssl version >/dev/null 2>&1);then
        log "try to install openssl"
        WANT_UPDATE="1" cops_pkgmgr_install.sh openssl
    fi
    if [ "x$NGINX_DH_FILE" != "x" ];then
        if [ ! -e "$NGINX_DH_FILE" ];then
            ddhparams=$(dirname $NGINX_DH_FILE)
            if [ ! -e "$ddhparams" ];then mkdir -pv "$ddhparams";fi
            openssl dhparam -out "$NGINX_DH_FILE" 2048
            chmod 644 "$NGINX_DH_FILE"
        fi
    fi
fi
DEFAULT_NGINX_DEBUG_BIN=$(which nginx-debug 2>/dev/null )
NGINX_DEBUG_BIN=${NGINX_DEBUG_BIN-$DEFAULT_NGINX_DEBUG_BIN}
# if debug is enabled, try to see if we need to switch binary
if ( egrep -rq "error_log .* debug" $NGINX_CONF_DIR ) && \
    [ "x$NGINX_DEBUG_BIN" != "x" ];then
    NGINX_BIN="$NGINX_DEBUG_BIN"
fi
if [ "x$NGINX_SKIP_CHECK" = "x" ];then
    $NGINX_BIN -t "$@"
fi
exec $NGINX_BIN "$@"
# vim:set et sts=4 ts=4 tw=80:
