#!/usr/bin/env bash
set -e
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
export NO_SUPERVISORD_LOGTAIL="${NO_SUPERVISORD_LOGTAIL-1}"
export SUPERVISORD_USER="${SUPERVISORD_USER:-supervisord}"
export SUPERVISORD_PASSWORD="${SUPERVISORD_PASSWORD:-supervisord}"
export SUPERVISORD_DIR="${SUPERVISORD_DIR:-"/etc/supervisord-go"}"
export SUPERVISORD_DEFAULT_CFG="${SUPERVISORD_DEFAULT_CFG:-"$SUPERVISORD_DIR/supervisord.conf"}"
export SUPERVISORD_SOCKET_PATH="${SUPERVISORD_SOCKET_PATH:-"$SUPERVISORD_DIR/sock/supervisord.sock"}"
export SUPERVISORD_SOCKET_DIR="$(dirname "$SUPERVISORD_SOCKET_PATH")"
export SUPERVISORD_PIDFILE="${SUPERVISORD_PIDFILE:-"$SUPERVISORD_DIR/supervisord.pid"}"
export SUPERVISORD_LOGSDIR="${SUPERVISORD_LOGSDIR:-"/var/log/supervisor"}"
if [ "x${NO_SUPERVISORD_LOGTAIL}" != "x" ];then
    export SUPERVISORD_LOGFILE="${SUPERVISORD_LOGFILE:-"/dev/stdout"}"
    export SUPERVISORD_LOGFILE_ERR="${SUPERVISORD_LOGFILE_ERR:-"/dev/stderr"}"
    export SUPERVISORD_LOGFILE_MAXBYTES="${SUPERVISORD_LOGFILE_MAXBYTES:-"50MB"}"
    export SUPERVISORD_LOGFILE_BACKUPS="${SUPERVISORD_LOGFILE_BACKUPS:-"31"}"
fi
export SUPERVISORD_LOGFILE_BACKUPS="${SUPERVISORD_LOGFILE_BACKUPS:-"0"}"
export SUPERVISORD_LOGFILE="${SUPERVISORD_LOGFILE:-"/var/log/supervisord_out"}"
export SUPERVISORD_LOGFILE_ERR="${SUPERVISORD_LOGFILE_ERR:-"/var/log/supervisord_err"}"
export SUPERVISORD_LOGFILE_MAXBYTES="${SUPERVISORD_LOGFILE_MAXBYTES:-"0"}"
export SUPERVISORD_HAS_HTTP="${SUPERVISORD_HAS_HTTP:-}"
export SUPERVISORD_HAS_SOCK="${SUPERVISORD_HAS_SOCK:-y}"
export SUPERVISORD_HTTP_HOST="${SUPERVISORD_HTTP_HOST:-127.0.0.1}"
export SUPERVISORD_HTTP_PORT="${SUPERVISORD_HTTP_PORT:-9001}"
export SUPERVISORD_LOGLEVEL="${SUPERVISORD_LOGLEVEL:-error}"
# make pipes for programs to push logs up to docker logs
DEFAULT_SUPERVISORD_CONFIG_TEMPLATE="
[supervisord]
# loglevel=$SUPERVISORD_LOGLEVEL
pidfile=%(here)s/$SUPERVISORD_DIR/supervisord.pid
identifier=supervisor
logfile=$SUPERVISORD_LOGFILE
stdout_logfile=$SUPERVISORD_LOGFILE
stderr_logfile=$SUPERVISORD_LOGFILE_ERR
logfile_maxbytes=$SUPERVISORD_LOGFILE_MAXBYTES
logfile_backups=$SUPERVISORD_LOGFILE_BACKUPS
"
if [ "x$SUPERVISORD_HAS_SOCK" != "x" ] || [ "x$SUPERVISORD_HAS_HTTP" != "x" ];then
  DEFAULT_SUPERVISORD_CONFIG_TEMPLATE="$DEFAULT_SUPERVISORD_CONFIG_TEMPLATE
[supervisorctl]
serverurl = unix://$SUPERVISORD_SOCKET_PATH
username=$SUPERVISORD_USER
password=$SUPERVISORD_PASSWORD
"
fi
if [ "x$SUPERVISORD_HAS_SOCK" != "x"  ];then
  if [ ! -e "$SUPERVISORD_SOCKET_DIR" ];then mkdir -p "$SUPERVISORD_SOCKET_DIR";fi
  DEFAULT_SUPERVISORD_CONFIG_TEMPLATE="$DEFAULT_SUPERVISORD_CONFIG_TEMPLATE
[unix_http_server]
file=$SUPERVISORD_SOCKET_PATH
username=$SUPERVISORD_USER
password=$SUPERVISORD_PASSWORD
"
fi
if [ "x$SUPERVISORD_HAS_HTTP" != "x" ];then
  DEFAULT_SUPERVISORD_CONFIG_TEMPLATE="$DEFAULT_SUPERVISORD_CONFIG_TEMPLATE
[inet_http_server]
port=$SUPERVISORD_HTTP_HOST:$SUPERVISORD_HTTP_PORT
username=$SUPERVISORD_USER
password=$SUPERVISORD_PASSWORD
"
fi
DEFAULT_SUPERVISORD_CONFIG_TEMPLATE="$DEFAULT_SUPERVISORD_CONFIG_TEMPLATE
#
# Programs
#

"
isodate() { date --utc '+%FT%TZ';  }
SUPERVISORD_LOGGER_TEMPO=${SUPERVISORD_LOGGER_TEMPO-10}
consume_pipes() {
    tag="${1}"
    shift
    lock=/tmp/supervisord_logger
    for i in $@;do
        (\
        while [ -e $lock ];do :;done && touch $lock \
        && tail -f "$i"\
        | while IFS= read -r line;do
          tlog="$tag::$(isodate)::$line" \
          && if ( echo "$tag"|grep -iq err);then echo "$tlog">&2;fi \
          && if ( echo "$tag"|grep -iq out);then echo "$tlog">&1;fi \
        ;done && rm $lock; )
    done
    sleep $SUPERVISORD_LOGGER_TEMPO
}
if [ "x${NO_SUPERVISORD_LOGTAIL}" = "x" ];then
    for i in $SUPERVISORD_LOGFILE $SUPERVISORD_LOGFILE_ERR;do
        di="$(dirname $i)"
        if [ ! -e "$di" ];then mkdir -p "$di";fi
        if [ ! -p "$i" ];then
            if [  -e "$i" ];then rm -f "$i";fi
            mkfifo "$i";chmod 660 "$i";chown root:daemon "$i"
        fi
    done
    ( while [ -e "$SUPERVISORD_LOGFILE" ];do \
        consume_pipes "SUPERVISORD_OUT" "$SUPERVISORD_LOGFILE";done )&
    ( while [ -e "$SUPERVISORD_LOGFILE_ERR" ];do \
        consume_pipes "SUPERVISORD_ERR" "$SUPERVISORD_LOGFILE_ERR";done )&
fi
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
SUPERVISORD_CONFIGS="${SUPERVISORD_CONFIGS-${@:-${DEFAULT_SUPERVISORD_CONFIGS}}}"

SUPERVISORD_CONFIGS_=
for i in $SUPERVISORD_CONFIGS;do
    j=$i
    if ! ( echo $i | egrep -q ^/ );then
        j=/etc/supervisor.d/$j
    fi
    if [ "x$SUPERVISORD_CONFIGS_" != "x" ];then
        SUPERVISORD_CONFIGS_="${SUPERVISORD_CONFIGS_} "
    fi
    SUPERVISORD_CONFIGS_="${SUPERVISORD_CONFIGS_}${j}"
done
SUPERVISORD_CONFIGS="$SUPERVISORD_CONFIGS_"

export SUPERVISORD_CONFIG_TEMPLATE="${SUPERVISORD_CONFIG_TEMPLATE:-${DEFAULT_SUPERVISORD_CONFIG_TEMPLATE}}"
if [ ! -e $SUPERVISORD_CFG ];then
    echo "${SUPERVISORD_CONFIG_TEMPLATE}" \
        > "$SUPERVISORD_CFG.template"
    for cfg in "${SUPERVISORD_CFG}.template" $SUPERVISORD_CONFIGS;do
        echo "Processing $cfg -> $SUPERVISORD_CFG" >&2
        cat "$cfg" | frep - >> "$SUPERVISORD_CFG"
    done
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
if [ "x$supervisorbin" = "x" ];then
    echo "Supervisord not found" >&2
    exit 1
fi
docker_quit() {
    for i in $SUPERVISORD_LOGFILE $SUPERVISORD_LOGFILE_ERR;do
        if [ -e $i ];then rm -f $i;fi
    done
    kill -$sig $pid || :
    exit $ret
}
if [ "x${NO_SUPERVISORD_LOGTAIL}" = "x" ];then
     ( $supervisorbin -c "$SUPERVISORD_CFG" )&
     pid=$!
     for i in INT TERM KILL;do trap "ret=\$?;sig=$i;docker_quit" $i;done
     wait $pid
else
    exec $supervisorbin -c "$SUPERVISORD_CFG"
fi
# vim:set et sts=4 ts=4 tw=80:
