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
export NGINX_INJECT_DIR="${NGINX_INJECT_DIR:/nginx.d}"
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
export NGINX_PASSWORDS_DIR="${NGINX_PASSWORDS_DIR:-/etc/htpasswd}"
export NGINX_PASSWORD_FILE="${NGINX_PASSWORD_FILE:-${NGINX_PASSWORDS_DIR}/protect}"
export NGINX_CONF_RENDER_DIR="${NGINX_CONF_RENDER_DIR:-"/tmp/nginxconf"}"
# let cron wrapper script use the custom nginx conf
export NO_NGINX_LOGROTATE=${NO_NGINX_LOGROTATE-}
export VHOST_TEMPLATES="${VHOST_TEMPLATES-"/etc/nginx/conf.d/default.conf"}"
export VHOST_TEMPLATE_EXTS="${VHOST_TEMPLATE_EXTS:-frep template}"
export NGINX_CONFIGS="${NGINX_CONFIGS-"
$(find "$NGINX_CONF_DIR" -type f |grep -E -v "$NGINX_FREP_SKIP|\.(${VHOST_TEMPLATE_EXTS// /|})$")
/etc/logrotate.d/nginx"}"
create_file() {
    for i in $@;do
        if [ ! -e "$(dirname $i)" ];then mkdir -p "$(dirname $i)";fi
        if [ -d "$i" ];then if [ "x$(ls -A "$i"||true)" = "x" ];then rm -rf "$i";fi;fi
        touch "$i" && chown $NGINX_USER:$NGINX_USER "$i" && chmod 640 "$i"
    done
}
log() { echo "$@" >&2; }
vv() { log "$@";"$@"; }
if [ "x${NGINX_USER}" = "x" ];then
    for i in www-data nginx www root;do
        if (getent passwd $i >/dev/null 2>&1);then NGINX_USER=$i;fi
    done
fi
# patch rsyslog default conf not to interfer with nginx self contained
for i in /etc/logrotate.d/rsyslog;do
    if [ -e $i ];then
        # do not crash on this
        ( sed -i -re "/\/nginx\/|nginx.log|\/\*-(error|access)/ d" $i || true)
    fi
done
# We search for XXX_HTTP_PROTECT_PASSWORD/XXX_HTTP_PROTECT_USER/XXX_HTTP_PROTECT_FILE envvars
# to generate relative htpasswd files
# Note that $NGINX_PASSWORD_FILE will receive all defined password pairs
OIFS=${IFS-}
IFS=$'\n'
for envline in $(env|grep -E "^([^\s ]+_)?HTTP_PROTECT_PASSWORD=");do
    password="$(echo $envline|sed -re "s/^([^=]+)=(.*)/\2/g")"
    variable="$(echo $envline|sed -re "s/^([^=]+)=(.*)/\1/g")"
    if [ "x${password}" != "x" ];then
        uservariable="$(echo $variable|sed -re "s/PASSWORD$/USER/g")"
        filevariable="$(echo $variable|sed -re "s/PASSWORD$/FILE/g")"
        prefix="$(echo "$variable"|tr '[:upper:]' '[:lower:]'|sed -re "s/_http_protect_password//gi")"
        default_passwdfile="$NGINX_PASSWORDS_DIR/${prefix}protect"
        echo $filevariable
        passwd_file="$(eval "echo "\${${filevariable}:-\$default_passwdfile}"")"
        passwd_user="$(eval "echo "\${${uservariable}:-root}"")"
        log "Generating HTPASSWD for $uservariable ($passwd_file & $NGINX_PASSWORD_FILE)"
        for i in "$passwd_file" "$NGINX_PASSWORD_FILE";do
            create_file "$i" && echo "$password"| htpasswd -bim "$i" "$passwd_user"
        done
    fi
done
IFS=${OIFS}
# retrocompat: link all subpassword files in /etc/htpasswd/* to /etc/htpasswd-$i counterparts
for i in $(find "$NGINX_PASSWORDS_DIR" -type f -maxdepth 1);do ln -sfv "$i" "/etc/htpasswd-$(basename $i)";done
###
if [[ -z ${NGINX_SKIP_EXPOSE_HOST} ]];then
    if ( ip -4 route list match 0/0 >/dev/null 2>&1 );then
        ip -4 route list match 0/0 | awk '{print $3" host.docker.internal"}' >> /etc/hosts
    fi
fi
if [ "x$NGINX_STD_OUTPUT" = "x" ] && [ "x$NGINX_AUTOCLEANUP_LOGS" != "x" ];then
    for i in $NGINX_LOGS_DIR;do rm -fv $NGINX_LOGS_DIR/*;done
fi
for e in $NGINX_LOGS_DIRS $NGINX_CONF_DIR;do
    if [ ! -e "$e" ];then mkdir -p "$e";fi
    if [ "x$NO_CHOWN" != "x" ] && [ -e "$e" ];then chown "$NGINX_USER" "$e";fi
done
if [ "x$SKIP_CONF_RENDER" = "x" ];then
    for i in $NGINX_CONFIGS;do frep "$i:$i" --overwrite;done
    for v in ${VHOST_TEMPLATES};do
        for e in ${VHOST_TEMPLATE_EXTS};do
            if [ -e $v.$e ];then frep "${v}.$e:$v" --overwrite;fi
        done
    done
fi
# also render an eventual /nginx.d folder
if [ "x$SKIP_EXTRA_CONF" = "x" ] && [ -e "$NGINX_INJECT_DIR" ];then
    log "Nginx conf injection directory present, processing"
    if [ -e "$NGINX_CONF_RENDER_DIR" ];then rm -rf "$NGINX_CONF_RENDER_DIR";fi
    mkdir -p "$NGINX_CONF_RENDER_DIR"
    cp -rf "$NGINX_INJECT_DIR"/* "$NGINX_CONF_RENDER_DIR"
    if [ "x$SKIP_CONF_RENDER" = "x" ];then
        for v in $(cd "$NGINX_CONF_RENDER_DIR" && find . -type f);do
            if (echo "$f" |grep -E -v "$NGINX_FREP_SKIP");then
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
                | grep -E "\s*ssl_dhparam" | grep -v "{{" \
                | awk '{print $2}'|sed -re "s/;//g"|awk '!seen[$0]++' );do
                NGINX_DH_FILES="$NGINX_DH_FILES $i"
            done
        else
            nginxconfs="$(find /etc/nginx/ -type f|xargs cat)"
            if [ "x$(echo "$nginxconfs"|wc -l)" != "x0" ];then
                for i in $( echo "$nginxconfs"\
                    | grep -E "\s*ssl_dhparam" | grep -v "{{" \
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
if ( grep -E -rvh "^(\s|\t| )*#" $NGINX_CONF_DIR | grep -E -rq "error_log .* debug" ) && \
    [ "x$NGINX_DEBUG_BIN" != "x" ];then
    NGINX_BIN="$NGINX_DEBUG_BIN"
fi
if [ "x$NGINX_SKIP_CHECK" = "x" ];then
    $NGINX_BIN -t "$@"
fi
set -x
exec $NGINX_BIN "$@"
# vim:set et sts=4 ts=4 tw=0:
