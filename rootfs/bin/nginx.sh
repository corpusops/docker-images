#!/usr/bin/env sh
set -e
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
NO_CHOWN=${NO_CHOWN-}
export NGINX_CONF_DIR="${NGINX_CONF_DIR:-"/etc/nginx"}"
# French legal http logs retention  is 3 years
export OPENSSL_INSTALL=${OPENSSL_INSTALL-}
export SKIP_EXTRA_CONF=${SKIP_EXTRA_CONF-}
export SKIP_CONF_RENDER=${SKIP_CONF_RENDER-}
export SKIP_OPENSSL_INSTALL=${SKIP_OPENSSL_INSTALL-}
export NO_DIFFIR=${NO_DIFFIE-}
export NO_SSL=${NO_SSL-1}
export SSL_CERTS_PATH=${SSL_CERTS_PATH:-"/certs"}
export SSL_CERT_BASENAME="${SSL_CERT_BASENAME:-"cert"}"
export SSL_CERT_PATH=${SSL_CERT_PATH:-"${SSL_CERTS_PATH}/$SSL_CERT_BASENAME.crt"}
export SSL_KEY_PATH=${SSL_KEY_PATH:-"${SSL_CERTS_PATH}/$SSL_CERT_BASENAME.key"}
export NGINX_HTTP_PROTECT_USER=${NGINX_HTTP_PROTECT_USER:-root}
export NGINX_HTTP_PROTECT_PASSWORD=${NGINX_HTTP_PROTECT_PASSWORD-}
export NGINX_SKIP_CHECK="${NGINX_SKIP_CHECK-}"
export NGINX_ROTATE_YEARS="${NGINX_ROTATE_YEARS:-1}"
export NGINX_ROTATE=${NGINX_ROTATE-$((365*${NGINX_ROTATE_YEARS}))}
export NGINX_USER=${NGINX_USER-"root"}
export NGINX_GROUP=${NGINX_GROUP-"nginx"}
export NGINX_STD_OUTPUT=${NGINX_STD_OUTPUT-}
export NGINX_AUTOCLEANUP_LOGS=${NGINX_AUTOCLEANUP_LOGS-}
export NGINX_RUN_DIR="${NGINX_RUN_DIR:-"/var/run"}"
export NGINX_PIDFILE="${NGINX_PIDFILE:-"${NGINX_RUN_DIR}/nginx.pid"}"
export NGINX_LOGS_DIR="${NGINX_LOGS_DIR:-"/var/log/nginx"}"
export NGINX_LOGS_DIRS="/logs /log $NGINX_LOGS_DIR"
export NGINX_SOCKET_DIR="$(dirname "$NGINX_SOCKET_PATH")"
export NGINX_BIN=${NGINX_BIN:-"nginx"}
export NGINX_FREP_SKIP=${NGINX_FREP_SKIP:-"(\.skip|\.skipped)$"}
export NGINX_SKIP_EXPOSE_HOST="${NGINX_SKIP_EXPOSE_HOST-}"
export NGINX_DH_FILE="${NGINX_DH_FILE-/certs/dhparams.pem}"
export NGINX_DH_FILES="$NGINX_DH_FILE"
export NGINX_CONF_RENDER_DIR="${NGINX_CONF_RENDER_DIR:-"/tmp/nginxconf"}"
# let cron wrapper script use the custom nginx conf
export NO_NGINX_LOGROTATE=${NO_NGINX_LOGROTATE-}
export NGINX_CONFIGS="${NGINX_CONFIGS-"$( \
    find "$NGINX_CONF_DIR" -type f \
    |egrep -v "$NGINX_FREP_SKIP|\.template$")
/etc/logrotate.d/nginx"}"
log() { echo "$@" >&2; }
vv() { log "$@";"$@"; }
touch /etc/htpasswd-protect
chmod 644 /etc/htpasswd-protect
if [ "x$NGINX_HTTP_PROTECT_PASSWORD" != "x" ];then
  echo "Activating htpasswd for $NGINX_HTTP_PROTECT_USER">&2
  echo "$NGINX_HTTP_PROTECT_PASSWORD" \
	  | htpasswd -bim /etc/htpasswd-protect "$NGINX_HTTP_PROTECT_USER"
fi
if [[ -z ${NGINX_SKIP_EXPOSE_HOST} ]];then
    ip -4 route list match 0/0 \
        | awk '{print $3" host.docker.internal"}' >> /etc/hosts
fi
if [ "x$NGINX_STD_OUTPUT" = "x" ] && [ "x$NGINX_AUTOCLEANUP_LOGS" != "x" ];then
    for i in $NGINX_LOGS_DIR;do rm -fv $NGINX_LOGS_DIR/*;done
fi
for e in $NGINX_LOGS_DIRS $NGINX_CONF_DIR;do
    if [ ! -e "$e" ];then mkdir -p "$e";fi
    if [ "x$NO_CHOWN" != "x" ] && [ -e "$e" ];then chown "$NGINX_USER" "$e";fi
done
if [ "x$SKIP_CONF_RENDER" = "x" ];then
    for i in $NGINX_CONFIGS;do frep $i:$i --overwrite;done
fi
# also render an eventual /nginx.d folder
if [ "x$SKIP_EXTRA_CONF" = "x" ] && [ -e /nginx.d ];then
    log "Nginx conf injection directory present, processing"
    if [ -e "$NGINX_CONF_RENDER_DIR" ];then
        rm -rf "$NGINX_CONF_RENDER_DIR"
    fi
    mkdir -p "$NGINX_CONF_RENDER_DIR"
    cp -rf /nginx.d/* "$NGINX_CONF_RENDER_DIR"
    if [ "x$SKIP_CONF_RENDER" = "x" ];then
        for v in $(cd "$NGINX_CONF_RENDER_DIR" && find . -type f);do
            if (echo "$f" |egrep -v "$NGINX_FREP_SKIP");then
                vv frep "$NGINX_CONF_RENDER_DIR/$v:$NGINX_CONF_RENDER_DIR/$v" --overwrite
            fi
        done
    fi
    cp -rvf $NGINX_CONF_RENDER_DIR/* /etc/nginx
fi
chmod 600 /etc/logrotate.d/nginx
if [ "x$NO_SSL" != "x1" ] || [ "x$NO_DIFFIE" != "x1" ] ;then OPENSSL_INSTALL=1;fi
if [ "x$SKIP_OPENSSL_INSTALL" != "x" ];then
    log "skip install openssl"
    OPENSSL_INSTALL=""
fi
if [ "x$OPENSSL_INSTALL" != "x" ] && ! (openssl version >/dev/null 2>&1);then
    log "try to install openssl"
    WANT_UPDATE="1" cops_pkgmgr_install.sh openssl
fi
if [ "x$NO_DIFFIE" = "x1" ];then
     log "no diffie setup"
else
    if ( $NGINX_BIN -h 2>&1|grep -q -- -T; );then
        if ( nginx -t &>/dev/null );then
            for i in $($NGINX_BIN -T \
                | egrep "\s*ssl_dhparam"\
                | awk '{print $2}'|sed -re "s/;//g"|awk '!seen[$0]++' );do
                NGINX_DH_FILES="$NGINX_DH_FILES $i"
            done
        else
            nginxconfs="$(find /etc/nginx/ -type f|xargs cat)"
            if [ "x$nginxconfs" != "x0" ];then
                for i in $( echo "$nginxconfs"\
                    | egrep "\s*ssl_dhparam"\
                    | awk '{print $2}'|sed -re "s/;//g"|awk '!seen[$0]++' );do
                    NGINX_DH_FILES="$NGINX_DH_FILES $i"
                done
            fi
        fi
    fi
    NGINX_DH_FILES="$(echo $NGINX_DH_FILES|xargs -n1|awk '!seen[$0]++')"
    for nginx_dh_file in $NGINX_DH_FILES;do
        if [ "x$NGINX_DH_FILE" = "x" ];then
            NGINX_DH_FILE="$nginx_dh_file"
        fi
        dodifcert=
        if [ -e "$nginx_dh_file" ];then
            if [ "x$(cat $nginx_dh_file)" = "x" ];then
            dodifcert=1
            fi
        fi
        if [ ! -e "$nginx_dh_file" ];then
            dodifcert=1
        fi
        if [ "x$dodifcert" != "x" ];then
            ddhparams=$(dirname $nginx_dh_file)
            if [ ! -e "$ddhparams" ];then mkdir -pv "$ddhparams";fi
            echo "Generating dhparams ($nginx_dh_file)" >&2
            openssl dhparam -out "$nginx_dh_file" 2048
            chmod 644 "$nginx_dh_file"
        fi
    done
    export NGINX_DH_FILES NGINX_DH_FILE
fi
if [ "x$NO_SSL" = "x1" ];then
    log "no ssl setup"
else
    if [ ! -e "$SSL_CERT_PATH" ] || [ ! -e "$SSL_KEY_PATH" ];then
        cops_gen_cert.sh
    fi
    log "$SSL_CERT_PATH found as SSL certificate"
fi
if [ -e /etc/nginx/nginx.conf ];then
    sed -i -re "s/user\s+.*;/user ${NGINX_USER};/g" /etc/nginx/nginx.conf
fi
DEFAULT_NGINX_DEBUG_BIN=$(which nginx-debug 2>/dev/null )
NGINX_DEBUG_BIN=${NGINX_DEBUG_BIN-$DEFAULT_NGINX_DEBUG_BIN}
# if debug is enabled, try to see if we need to switch binary
if ( egrep -rvh "^(\s|\t| )*#" $NGINX_CONF_DIR | egrep -rq "error_log .* debug" ) && \
    [ "x$NGINX_DEBUG_BIN" != "x" ];then
    NGINX_BIN="$NGINX_DEBUG_BIN"
fi
if [ "x$NGINX_SKIP_CHECK" = "x" ];then
    $NGINX_BIN -t "$@"
fi
set -x
exec $NGINX_BIN "$@"
# vim:set et sts=4 ts=4 tw=80:
