#!/usr/bin/env sh
set -e
if [ "x${SDEBUG}" = "x" ];then set x;fi
RSYSLOGD_BIN=${RSYSLOGD_BIN:-"rsyslogd"}
RSYSLOGD_ARGS=${RSYSLOGD_ARGS:-"-n"}
NO_DEFAULT_RSYSLOGD_CONF=${NO_DEFAULT_RSYSLOGD_CONF-}
NO_DEFAULT_RSYSLOG_CONF=${NO_DEFAULT_RSYSLOG_CONF-}
NO_DEFAULT_LOGROTATE_CONF=${NO_DEFAULT_LOGROTATE_CONF-}
export RSYSLOG_INJECT_DIR=${RSYSLOG_INJECT_DIR:-/entry}
export LOGROTATE_CONF_DIR=${LOGROTATE_CONF_DIR:-/etc/logrotate.d}
export RSYSLOG_CONF_DIR=${RSYSLOG_CONF_DIR:-/etc/rsyslog.d}
export RSYSLOG_SPLITTED_CONFIGS=${RSYSLOG_SPLITTED_CONFIGS-}
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
if [ -e "$RSYSLOG_INJECT_DIR" ];then
    cp -rfv "$RSYSLOG_INJECT_DIR"/. /etc/
fi
if [ "x${NO_DEFAULT_RSYSLOG_CONF}" = "x" ] && [ -e /etc/rsyslog.conf.frep ];then
    frep --overwrite /etc/rsyslog.conf.frep:/etc/rsyslog.conf
fi
if [ "x${NO_DEFAULT_LOGROTATE_CONF}" = "x" ] && [ -e $LOGROTATE_CONF_DIR ];then
    for i in $(ls $LOGROTATE_CONF_DIR/*.conf.frep 2>/dev/null || true);do
        frep "$i:$LOGROTATE_CONF_DIR/$(basename $i .frep)" --overwrite
        rm -fv "$i"
    done
fi
if [ "x${NO_DEFAULT_RSYSLOGD_CONF}" = "x" ] && [ -e $RSYSLOG_CONF_DIR ];then
    for i in $(ls $RSYSLOG_CONF_DIR/*.conf.frep 2>/dev/null || true);do
        frep "$i:$RSYSLOG_CONF_DIR/$(basename $i .frep)" --overwrite
    done
fi
if [ "x${RSYSLOG_SPLITTED_CONFIGS}" = "x" ];then
    rm -f $RSYSLOG_CONF_DIR/50-dockerlog.conf || true
fi
exec $RSYSLOGD_BIN $RSYSLOGD_ARGS
# vim:set et sts=4 ts=4 tw=80:
