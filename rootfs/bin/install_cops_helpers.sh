#!/usr/bin/env sh
SKIP_HELPERS_SERVICE="${HELPERS_SERVICE-1}"
HELPERS_DIR="${HELPERS_DIR:-/helpers}"
HELPERS_FLAG="${HELPERS_FLAG:-$HELPERS_DIR/.started}"
if [ ! -e "$HELPERS_DIR" ];then mkdir -pv "$HELPERS_DIR";fi
if [ -e "$HELPERS_FLAG" ];then rm -f "$HELPERS_FLAG";fi
if ( rsync --version >/dev/null 2>&1 );then
    rsync -av /cops_helpers/ $HELPERS_DIR/
else
    cp -arfv /cops_helpers/* $HELPERS_DIR/
fi
touch "$HELPERS_FLAG"
if [ "x${SKIP_HELPERS_SERVICE}" = "x" ];then
    while true;do
        printf "HTTP/1.1 200 OK\n\nstarted" | ( nc -l -p 80 || /bin/true)
    done
fi
# vim:set et sts=4 ts=4 tw=0:
