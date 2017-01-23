#!/usr/bin/env sh
set -e
# to be added inside vanilla images to infest from corpusops image mounted via buildkit in /s prefix
NO_PKGS_INSTALL=${NO_PKGS_INSTALL-}
NO_HELPERS_SYNC=${NO_HELPERS_SYNC-}
# assuming we are in $prefix/bin
if [ "x${SDEBUG-}" != "x" ];then set -x;fi
W=$(cd $(dirname $(readlink -f $0)) && pwd)
T=$(cd $W/.. && pwd)
log() { echo $@ >&2; }
pkgs=""
cd "$T"
if [ "x$NO_PKGS_INSTALL" = "x" ];then
    for i in logrotate rsync rsyslog curl openssh-client;do
        if ! ( $i --version &>/dev/null );then
            log "installing $i"
            pkgs="$pkgs $i"
        fi
    done
    if ( apk --version &>/dev/null );then
        pkgs="$pkgs dcron"
    else
        pkgs="$pkgs cron"
    fi
    if [ "x$pkgs" != "x" ];then
       WANTED_EXTRA_PACKAGES="$pkgs" $W/cops_pkgmgr_install.sh
    fi
fi
if [ "x$NO_HELPERS_SYNC" = "x" ] && ! ( echo $T | grep -E -q "^/$" );then
    for i in \
        etc/rsyslog.d/ \
        etc/supervisor.d/ \
        etc/logrotate.d/ \
        bin/cron.sh \
        bin/rsyslog.sh \
        cops_helpers/
        do
            rsync -aAHv --numeric-ids $i /$i
        done
fi
cd -
# vim:set et sts=4 ts=4 tw=0:
