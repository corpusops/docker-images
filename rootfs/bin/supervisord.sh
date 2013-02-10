#!/usr/bin/env bash
set -e
SUPERVISORD_CONF_PREFIX="${SUPERVISORD_CONF_PREFIX:-${CONF_PREFIX:-SUPERVISORD_}}"
get_conf_vars() {
    echo $( env | egrep "${CONF_PREFIX}[^=]+=.*" \
            | sed -re "s/((${CONF_PREFIX})[^=]+)=.*/$\1;/g";); }
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
export SUPERVISORD_USER="${SUPERVISORD_USER:-supervisord}"
export SUPERVISORD_PASSWORD="${SUPERVISORD_PASSWORD:-supervisord}"
export SUPERVISORD_DIR="${SUPERVISORD_DIR:-"/etc/supervisord-go"}"
export SUPERVISORD_DEFAULT_CFG="${SUPERVISORD_DEFAULT_CFG:-"$SUPERVISORD_DIR/supervisord.conf"}"
export SUPERVISORD_SOCKET_PATH="${SUPERVISORD_SOCKET_PATH:-"$SUPERVISORD_DIR/sock/supervisord.sock"}"
export SUPERVISORD_SOCKET_DIR="$(dirname "$SUPERVISORD_SOCKET_PATH")"
export SUPERVISORD_PIDFILE="${SUPERVISORD_PIDFILE:-"$SUPERVISORD_DIR/supervisord.pid"}"
export SUPERVISORD_LOGSDIR="${SUPERVISORD_LOGSDIR:-"/var/log/supervisor"}"
export SUPERVISORD_LOGFILE="${SUPERVISORD_LOGFILE:-"/dev/stdout"}"
export SUPERVISORD_LOGFILE="${SUPERVISORD_LOGFILE:-"$SUPERVISORD_LOGSDIR/supervisord.log"}"
export SUPERVISORD_HAS_HTTP="${SUPERVISORD_HAS_HTTP:-}"
export SUPERVISORD_HAS_SOCK="${SUPERVISORD_HAS_SOCK:-y}"
export SUPERVISORD_HTTP_HOST="${SUPERVISORD_HTTP_HOST:-127.0.0.1}"
export SUPERVISORD_HTTP_PORT="${SUPERVISORD_HTTP_PORT:-9001}"
export SUPERVISORD_LOGLEVEL="${SUPERVISORD_LOGLEVEL:-error}"
export SUPERVISORD_LOGFILE_MAXBYTES="${SUPERVISORD_LOGFILE_MAXBYTES:-"50MB"}"
export SUPERVISORD_LOGFILE_BACKUPS="${SUPERVISORD_LOGFILE_BACKUPS:-"31"}"
DEFAULT_CONFIG_TEMPLATE="
[supervisord]
# loglevel=$SUPERVISORD_LOGLEVEL
pidfile=%(here)s/$SUPERVISORD_DIR/supervisord.pid
identifier=supervisor
logfile=$SUPERVISORD_LOGFILE
"
if ! ( echo $SUPERVISORD_LOGFILE|egrep -q /dev/std );then
DEFAULT_CONFIG_TEMPLATE="$DEFAULT_CONFIG_TEMPLATE
logfile_maxbytes=$SUPERVISORD_LOGFILE_MAXBYTES
logfile_backups=$SUPERVISORD_LOGFILE_BACKUPS
"
fi
if [[ -n $SUPERVISORD_HAS_SOCK ]] || [[ -n $SUPERVISORD_HAS_HTTP ]];then
  DEFAULT_CONFIG_TEMPLATE="$DEFAULT_CONFIG_TEMPLATE
[supervisorctl]
serverurl = unix://$SUPERVISORD_SOCKET_PATH
username=$SUPERVISORD_USER
password=$SUPERVISORD_PASSWORD
"
fi
if [[ -n $SUPERVISORD_HAS_SOCK ]];then
  if [ ! -e "$SUPERVISORD_SOCKET_DIR" ];then mkdir -p "$SUPERVISORD_SOCKET_DIR";fi
  DEFAULT_CONFIG_TEMPLATE="$DEFAULT_CONFIG_TEMPLATE
[unix_http_server]
file=$SUPERVISORD_SOCKET_PATH
username=$SUPERVISORD_USER
password=$SUPERVISORD_PASSWORD
"
fi
if [[ -n $SUPERVISORD_HAS_HTTP ]];then
  DEFAULT_CONFIG_TEMPLATE="$DEFAULT_CONFIG_TEMPLATE
[inet_http_server]
port=$SUPERVISORD_HTTP_HOST:$SUPERVISORD_HTTP_PORT
username=$SUPERVISORD_USER
password=$SUPERVISORD_PASSWORD
"
fi
DEFAULT_CONFIG_TEMPLATE="$DEFAULT_CONFIG_TEMPLATE
#
# Programs
#
"
for i in $SUPERVISORD_LOGSDIR $SUPERVISORD_DIR;do
    if [ ! -e "$i" ];then mkdir -p "$i";fi
done
SUPERVISORD_CFG="${SUPERVISORD_CFG:-"$SUPERVISORD_DIR/supervisord.conf"}"
DEFAULT_SUPERVISORD_CONFIGS="
$( (find /etc/supervisord.d /etc/supervisor.d -type f 2>/dev/null || /bin/true)|grep -v $SUPERVISORD_CFG|sort -d|awk '!seen[$0]++')
$( (find \
    /etc/supervisor $SUPERVISORD_DIR /etc/supervisord \
    -type f -and \( -name '*.conf' -or -name '*.ini' \) -and min-depth 2\
    2>/dev/null|grep -v $SUPERVISORD_CFG ||/bin/true)|sort -d| awk '!seen[$0]++')"
SUPERVISORD_CONFIGS="${SUPERVISORD_CONFIGS-${DEFAULT_SUPERVISORD_CONFIGS}}"
if [ ! -e $SUPERVISORD_CFG ];then
    echo "$DEFAULT_CONFIG_TEMPLATE" | envsubst "$(get_conf_vars)" \
        > "$SUPERVISORD_CFG.template"
    ENVSUBST_DEST="$SUPERVISORD_CFG" CONF_PREFIX="$SUPERVISORD_CONF_PREFIX" \
        confenvsubst.sh ${SUPERVISORD_CFG}.template $SUPERVISORD_CONFIGS
fi
get_command() {
    local p=
    local cmd="${@}"
    if ( which which >/dev/null 2>/dev/null );then
        p=$(which "${cmd}" 2>/dev/null||/bin/true)
    fi
    if [ "x${p}" = "x" ];then
        p=$(export IFS=":";
            for pathe in $PATH;do
                pc="${pathe}/${cmd}";
                if [ -x "${pc}" ]; then
                    p="${pc}"
                fi
                if [ "x${p}" != "x" ]; then echo "${p}";break;fi
            done
         )
    fi
    if [ "x${p}" != "x" ];then
        echo "${p}"
    fi
}
for csupervisorbin in supervisord-go supervisord;do
    supervisorbin=$(get_command $csupervisorbin)
    if ( $supervisorbin version >/dev/null 2>&1 || $supervisorbin -v >/dev/null 2>&1);then break;fi
done
if [[ -z $supervisorbin ]];then
    echo "Supervisord not found" >&2
    exit 1
fi
exec $supervisorbin -c "$SUPERVISORD_CFG"
# vim:set et sts=4 ts=4 tw=80:
