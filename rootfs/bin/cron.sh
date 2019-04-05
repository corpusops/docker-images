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
# update default values of PAM environment variables (used by CRON scripts)
if [ -e /etc/pam.d/cron ];then
    sed -i -re "s/^session    required     pam_loginuid.so/#session    required   pam_loginuid.so/g" /etc/pam.d/cron
fi
if [ -e /etc/security/pam_env.conf ];then
    env | grep -- = | while read -r line; do  # read STDIN by line
        # split LINE by "="
        var=$(echo "$line"|sed -re "s/\s*=.*//g")
        val=$(echo "$line"|sed -re "s/^[^=]+=\s*//g")
        # remove existing definition of environment variable, ignoring exit code
        sed --in-place "/^${var}[[:blank:]=]/d" /etc/security/pam_env.conf || true
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
