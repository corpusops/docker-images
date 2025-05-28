#!/usr/bin/env sh
# Wrapper to cron
set -e
CROND_LOG=/var/log/cron.log
NO_CROND_LOG_PIPE=${NO_CROND_LOG_PIPE-}
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
if [ -e $CROND_LOG ];then rm -f $CROND_LOG;fi
DCRON_VERBOSE=${DCRON_VERBOSE:-2}
DEB_ARGS=${DEB_CRON_ARGS:-"-L 15 -f"}
DCRON_ARGS=${DCRON_ARGS:-"-b -l $DCRON_VERBOSE -S -f"}
CRONIE_ARGS=${CRONIE_ARGS:-"-n -s"}
CRON_CMD=${CRON_CMD-}
CRON_IMPLEMENTATION=${CRON_IMPLEMENTATION-}
LOGROTATE_WEB_PATTERN=${LOGROTATE_WEB_PATTERN:-365}
LOGROTATE_DAYS_PATTERN=${LOGROTATE_DAYS_PATTERN:-"[0-9]"}
LOGROTATE_WEB_DAYS=${LOGROTATE_WEB_DAYS:-365}
LOGROTATE_DAYS=${LOGROTATE_DAYS:-7}
LOGROTATE_LONGRETENTION_DAYS=${LOGROTATE_LONGRETENTION_DAYS:-${LOGROTATE_DAYS:-30}}
LOGROTATE_SIZE=${LOGROTATE_SIZE:-5M}
RSYSLOG_DOCKER_LOGS_PATH="${RSYSLOG_DOCKER_LOGS_PATH:-"/var/log/docker"}"
RSYSLOG_DOCKER_LONGRETENTION_LOGS_PATH="${RSYSLOG_DOCKER_LONGRETENTION_LOGS_PATH:-"/var/log/docker/longretention"}"

export SYSLOG_ONLY=${SYSLOG_ONLY-}
# update default values of PAM environment variables (used by CRON scripts)
if [ -e /etc/pam.d/cron ];then
    sed -i -re "s/^session    required     pam_loginuid.so/#session    required   pam_loginuid.so/g" /etc/pam.d/cron
fi
logrotateconf=/etc/logrotate.d/rsyslog
fixlogrotateconf() {
    if [  ! -e $1 ];then return;fi
    if [ "x${2-}" != "x" ];then shift;fi
    chmod -v g-wx,o-wx $@
}
if [ -e $logrotateconf ];then
    sed -i -r \
        -e "s/rotate $LOGROTATE_WEB_PATTERN/rotate $LOGROTATE_WEB_DAYS/g" \
        -e "s/rotate ${LOGROTATE_DAYS_PATTERN}$/rotate $LOGROTATE_DAYS/g" \
        -e "s/size .*/size $LOGROTATE_SIZE/g" \
        -e "s|/var/log/docker/\*|$RSYSLOG_DOCKER_LOGS_PATH/*|g" \
        -e "s|/var/log/docker/longretention|$RSYSLOG_DOCKER_LONGRETENTION_LOGS_PATH|g" \
        $logrotateconf
    if [ "x$SYSLOG_ONLY" != "x" ];then
        for i in /etc/logrotate.d/nginx;do if [ -e "$i" ];then rm -f "$i";fi;done
    fi
    fixlogrotateconf /etc/logrotate.d "/etc/logrotate.d/*"
    fixlogrotateconf /etc/logrotate.conf
fi
if [ -e /etc/security/pam_env.conf ];then
    # split LINE by "=", multiline values are unsupported as pam_env wont eat them
    for var in $(awk 'BEGIN{for (i in ENVIRON) {print i}}');do
        val="$(eval echo '"$'"$var"'"')"
        if $(echo "$val"|grep -qzP "\\n.*\\n");then
            echo "Unsetting multiline envvar: \$$var"
            eval "unset $var" || true
            continue
        fi
        # remove existing definition of environment variable, ignoring exit code
        sed --in-place "/^$(echo ${var})[[:blank:]=]/d" /etc/security/pam_env.conf || true
        # append new default value of environment variable
        echo "${var} DEFAULT=\"${val}\"" >> /etc/security/pam_env.conf
    done
fi
SUPERVISORD_LOGFILE="${SUPERVISORD_LOGFILE:-"/var/log/supervisord_out"}"
if [ "x$NO_CROND_LOG_PIPE" = "x" ];then
    # if was launch through supervisor, use it's named pipe to log
    if [ -e "$SUPERVISORD_LOGFILE" ] && [ "x$CROND_LOG" != "x$SUPERVISORD_LOGFILE" ];then
        ln -sf "$SUPERVISORD_LOGFILE" "$CROND_LOG"
    # init the $CROND_LOG and make dockerd move it to COW layer !
    elif [ -e "$CROND_LOG" ];then
        rm -f "$CROND_LOG"
        mkfifo "$CROND_LOG"
        chmod 660 "$CROND_LOG"
        echo started >> $CROND_LOG
    fi
    if [ ! -e /var/log/crond.log ] && \
        [ "x/var/log/crond.log" != "x$CROND_LOG" ];then
        ln -sf $CROND_LOG /var/log/crond.log
    fi
fi
# make busy box in fallback of systems implementations
if [ "x$CRON_CMD" != "x" ];then
    :
elif ( which cron >/dev/null 2>&1 );then
    CRON_CMD=cron
    CRON_IMPLEMENTATION=vixie
elif ( which busybox >/dev/null 2>&1 );then
    CRON_CMD="busybox crond"
    CRON_IMPLEMENTATION=dcron
elif ( which crond >/dev/null 2>&1 );then
    if ( ( yum list installed 2>&1 || /bin/true )|grep -q cronie ); then
        CRON_CMD=crond
        CRON_IMPLEMENTATION=cronie
    else
        if ( ( crond -V 2>&1 || /bin/true )|grep -q cronie );then
             CRON_CMD=cronie
             CRON_IMPLEMENTATION=cronie
        else
             CRON_CMD=crond
             CRON_IMPLEMENTATION=dcron
        fi
    fi
fi
if [ "x$CRON_IMPLEMENTATION" = "x" ];then
    :
elif [ "x$CRON_IMPLEMENTATION" = "xvixie" ];then
    variant_args=$DEB_ARGS
elif [ "x$CRON_IMPLEMENTATION" = "xdcron" ];then
    variant_args=$DCRON_ARGS
elif [ "x$CRON_IMPLEMENTATION" = "xcronie" ];then
    variant_args=$CRONIE_ARGS
else
    echo "not a supported cron implementation: $CRON_CMD/$CRON_IMPLEMENTATION"
    exit 1
fi
echo "Using cron: $CRON_CMD/$CRON_IMPLEMENTATION" >&2
exec $CRON_CMD $variant_args
# vim:set et sts=4 ts=4 tw=80:
