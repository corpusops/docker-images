#!/usr/bin/env sh
set -e
if [ "x${SDEBUG}" = "x" ];then set x;fi
RSYSLOGD_BIN=${RSYSLOGD_BIN:-"rsyslogd"}
RSYSLOGD_ARGS=${RSYSLOGD_ARGS:-"-n"}
NO_DEFAULT_RSYSLOG_CONF=${NO_DEFAULT_RSYSLOG_CONF-}
export RSYSLOG_CONF_DIR=${RSYSLOG_CONF_DIR:-/etc/rsyslog.d}
export RSYSLOG_SPLITTED_CONFIGS=${RSYSLOG_SPLITTED_CONFIGS-}
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
if [ "x${NO_DEFAULT_RSYSLOG_CONF}" = "x" ] && [ -e /etc/rsyslog.conf.frep ];then
    frep --overwrite /etc/rsyslog.conf.frep:/etc/rsyslog.conf
fi
for i in $(ls $RSYSLOG_CONF_DIR/*.conf.frep 2>/dev/null || true);do
    frep "$i:$RSYSLOG_CONF_DIR/$(basename $i .frep)" --overwrite
done
if [ "x${RSYSLOG_SPLITTED_CONFIGS}" = "x" ];then
    rm -f $RSYSLOG_CONF_DIR/50-dockerlog.conf || true
fi
exec $RSYSLOGD_BIN $RSYSLOGD_ARGS
# vim:set et sts=4 ts=4 tw=80:
