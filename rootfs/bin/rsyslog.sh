#!/usr/bin/env sh
set -e
RSYSLOGD_BIN=${RSYSLOGD_BIN:-"rsyslogd"}
RSYSLOGD_ARGS=${RSYSLOGD_ARGS:-"-n"}
NO_DEFAULT_RSYSLOG_CONF=${NO_DEFAULT_RSYSLOG_CONF-}
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
if [ "x${NO_DEFAULT_RSYSLOG_CONF}" = "x" ] && [ -e /etc/rsyslog.conf.frep ];then
    frep --overwrite /etc/rsyslog.conf.frep:/etc/rsyslog.conf
fi
for i in $(ls /etc/rsyslog.d/*.conf.frep 2>/dev/null || true);do
    if (grep -q -- {{ "$i" );then
        frep "$i:$(basename $i .frep)" --overwrite
    fi
done
exec $RSYSLOGD_BIN $RSYSLOGD_ARGS
# vim:set et sts=4 ts=4 tw=80:
