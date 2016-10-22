#!/usr/bin/env sh
CONF_PREFIX=FOREGO_
get_conf_vars() {
    echo $( env | egrep "${CONF_PREFIX}[^=]+=.*" \
    | sed -e "s/\(${CONF_PREFIX}[^=]\+\)=.*/$\1;/g";); }
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
export FOREGO_PROCFILE="${FOREGO_PROCFILE-${PROCFILE-}}"
export FOREGO_PROCFILES_DIR="${FOREGO_PROCFILES_DIR:-"/etc/procfiles"}"
export FOREGO_PROCFILES="
$( find $FOREGO_PROCFILES_DIR -type f 2>/dev/null|grep -v .run)"
export FOREGO_BIN="${FOREGO_BIN:-"forego"}"
export FOREGO_ARGS="${FOREGO_ARGS}"
for e in $FOREGO_CONF_DIR;do if [ ! -e "$e" ];then mkdir -p "$e";fi;done
if [ "x$FOREGO_PROCFILE" != "x" ];then
    export FOREGO_PROCFILES="$FOREGO_PROCFILES $FOREGO_PROCFILE"
    export FOREGO_ARGS="$FOREGO_ARGS -f ${FOREGO_PROCFILE}.run"
fi
for i in $FOREGO_PROCFILES;do if [ -e "$i" ];then
    echo "Running envsubst on $i" >&2
    content="$(cat $i)"
    echo "$content" | envsubst "$(get_conf_vars)" > "${i}.run"
fi;done
$FOREGO_BIN ${@:-start} $FOREGO_ARGS
# vim:set et sts=4 ts=4 tw=80:
