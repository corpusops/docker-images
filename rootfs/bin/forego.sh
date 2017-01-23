#!/usr/bin/env sh
set -e
FOREGO_CONF_PREFIX="${FOREGO_CONF_PREFIX:-${CONF_PREFIX:-FOREGO_}}"
get_conf_vars() {
    echo $( env | grep -E "${CONF_PREFIX}[^=]+=.*" \
            | sed -re "s/((${CONF_PREFIX})[^=]+)=.*/$\1;/g";); }
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
export FOREGO_PROCFILE="${FOREGO_PROCFILE-${PROCFILE-}}"
export FOREGO_PROCFILES_DIR="${FOREGO_PROCFILES_DIR:-"/etc/procfiles"}"
if [ "x$FOREGO_PROCFILE" != "x" ] && [ -e "$FOREGO_PROCFILE" ];then
    export FOREGO_PROCFILES="$FOREGO_PROCFILE"
else
    export FOREGO_PROCFILES="
    $( (find $FOREGO_PROCFILES_DIR -type f 2>/dev/null||/bin/true)|grep -v .run)"
fi
export FOREGO_BIN="${FOREGO_BIN:-"forego"}"
export FOREGO_ARGS="${FOREGO_ARGS}"
for e in $FOREGO_CONF_DIR;do if [ ! -e "$e" ];then mkdir -p "$e";fi;done
FOREGO_CONFIGS=""
for i in $FOREGO_PROCFILES;do if [ -e "$i" ];then
    FOREGO_CONFIGS="$FOREGO_CONFIGS $i.run"
    cp -p "$i" "$i.run"
    export FOREGO_ARGS="$FOREGO_ARGS -f ${i}.run"
fi;done
if [ "x$FOREGO_CONFIGS" != "x" ];then
    CONF_PREFIX="$FOREGO_CONF_PREFIX" confenvsubst.sh $FOREGO_CONFIGS
fi
exec $FOREGO_BIN ${@:-start} $FOREGO_ARGS
# vim:set et sts=4 ts=4 tw=80:
