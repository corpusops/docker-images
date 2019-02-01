#!/usr/bin/env sh
set -e
RSYSLOGD_BIN=${RSYSLOGD_BIN:-"rsyslogd"}
RSYSLOGD_ARGS=${RSYSLOGD_ARGS:-"-n"}
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
if [ -e /etc/rsyslog.conf.frep ];then
    frep --overwrite /etc/rsyslog.conf.frep:/etc/rsyslog.conf
fi
exec $RSYSLOGD_BIN $RSYSLOGD_ARGS
# vim:set et sts=4 ts=4 tw=80:
