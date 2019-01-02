#!/usr/bin/env sh
CONF_PREFIX=NGINX_
get_conf_vars() {
    echo $( env | egrep "${CONF_PREFIX}[^=]+=.*" \
    | sed -e "s/\(${CONF_PREFIX}[^=]\+\)=.*/$\1;/g";); }
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
NO_CHOWN=${NO_CHOWN-}
export NGINX_CONF_DIR="${NGINX_CONF_DIR:-"/etc/nginx"}"
export # French legal http logs retention  is 3 years
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
export NGINX_CONFIGS="${NGINX_CONFIGS-"$( find $NGINX_CONF_DIR -type f)
/etc/logrotate.d/nginx"}"
if [[ -z $NGINX_STD_OUTPUT ]];then rm -fv $NGINX_LOGS_DIR/*;fi
for e in $NGINX_LOGS_DIRS $NGINX_CONF_DIR;do
    if [ ! -e "$e" ];then mkdir -p "$e";fi
    if [ "x$NO_CHOWN" != "x" ] && [ -e "$e" ];then chown "$NGINX_USER" "$e";fi
done
for i in $NGINX_CONFIGS;do if [ -e "$i" ];then
    echo "Running envsubst on $i" >&2
    content="$(cat $i)"
    dest=$i
    if ( echo $i|egrep -q '\.template$' );then dest=$(basename $i .template);fi
    echo "$content"|envsubst "$(get_conf_vars)" > "$dest"
fi;done
chmod 600 /etc/logrotate.d/nginx
exec $NGINX_BIN "$@"
# vim:set et sts=4 ts=4 tw=80:
