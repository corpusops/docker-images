#!/usr/bin/env bash
CONF_PREFIX=SUPERVISORD_
get_conf_vars() {
    echo $( env | egrep "${CONF_PREFIX}[^=]+=.*" \
    | sed -e "s/\(${CONF_PREFIX}[^=]\+\)=.*/$\1;/g";); }
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
export SUPERVISORD_USER="${SUPERVISORD_USER:-supervisord}"
export SUPERVISORD_PASSWORD="${SUPERVISORD_PASSWORD:-supervisord}"
export SUPERVISORD_DIR="${SUPERVISORD_DIR:-"/etc/supervisord"}"
export SUPERVISORD_DEFAULT_CFG="${SUPERVISORD_DEFAULT_CFG:-"$SUPERVISORD_DIR/supervisord.conf"}"
export SUPERVISORD_SOCKET_PATH="${SUPERVISORD_SOCKET_PATH:-"$SUPERVISORD_DIR/sock/supervisord.sock"}"
export SUPERVISORD_SOCKET_DIR="$(dirname "$SUPERVISORD_SOCKET_PATH")"
export SUPERVISORD_PIDFILE="${SUPERVISORD_PIDFILE:-"$SUPERVISORD_DIR/supervisord.pid"}"
export SUPERVISORD_LOGSDIR="${SUPERVISORD_LOGSDIR:-"/var/log/supervisor"}"
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
logfile=$SUPERVISORD_LOGFILE
logfile_maxbytes=$SUPERVISORD_LOGFILE_MAXBYTES
logfile_backups=$SUPERVISORD_LOGFILE_BACKUPS
# loglevel=$SUPERVISORD_LOGLEVEL
pidfile=%(here)s/$SUPERVISORD_DIR/supervisord.pid
identifier=supervisor
"
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
for i in $SUPERVISORD_LOGSDIR $SUPERVISORD_DIR;do
    if [ ! -e "$i" ];then mkdir -p "$i";fi
done
SUPERVISORD_CFG="${SUPERVISORD_CFG:-"$SUPERVISORD_DIR/supervisord.conf"}"
cfgs="
$(find /etc/supervisor.d -type f \
    2>/dev/null|grep -v $SUPERVISORD_CFG|sort -d)
$(find /etc/supervisor /etc/supervisord -type f \
    -and \( -name '*.conf' -or -name '*.ini' \) \
    2>/dev/null|grep -v $SUPERVISORD_CFG|sort -d)"
if [ ! -e $SUPERVISORD_CFG ];then
    echo "$DEFAULT_CONFIG_TEMPLATE" \
        | envsubst "$(get_conf_vars)" > "$SUPERVISORD_CFG"
    while read cfg;do if [ -e "$cfg" ];then
        echo "Running envsubst on $cfg" >&2
        echo >> "$SUPERVISORD_CFG"
        envsubst "$(get_conf_vars)" >> "$SUPERVISORD_CFG" < "$cfg"
    fi
    done <<< "$SUPERVISORD_CFG.template
$cfgs"
fi
get_command() {
    local p=
    local cmd="${@}"
    if which which >/dev/null 2>/dev/null;then
        p=$(which "${cmd}" 2>/dev/null)
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
    if ( $supervisorbin version || $supervisorbin -v );then break;fi
done
if [[ -z $supervisorbin ]];then
    echo "Supervisord not found" >&2
    exit 1
fi
exec $supervisorbin -c "$SUPERVISORD_CFG"
# vim:set et sts=4 ts=4 tw=80:
