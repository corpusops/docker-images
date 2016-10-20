#!/usr/bin/env sh
CONF_PREFIX=TRAEFIC_
get_conf_vars() {
    echo $( env | egrep "${CONF_PREFIX}[^=]+=.*" \
    | sed -e "s/\(${CONF_PREFIX}[^=]\+\)=.*/$\1;/g";); }
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
export NO_ENVSUBST=""
export TRAEFIC_CONFIGS=""
export TRAEFIC_BIN="${TRAEFIC_BIN:-"traefic"}"
export TRAEFIC_ARGS="${TRAEFIC_ARGS-}"
export TRAEFIC_DEFAULT_CONFIG=""
if ! ( echo "$@" |egrep -q -- ' -c |--config' );then
    export TRAEFIC_DEFAULT_CONFIG="/traefic.toml"
fi
export TRAEFIC_CONFIG="${TRAEFIC_CONFIG:-${TRAEFIC_DEFAULT_CONFIG}}"
for e in $TRAEFIC_CONF_DIR;do if [ ! -e "$e" ];then mkdir -p "$e";fi;done
if [ -e "$TRAEFIC_CONFIG" ];then
    export TRAEFIC_CONFIGS="$TRAEFIC_CONFIGS $TRAEFIC_CONFIG"
    export TRAEFIC_ARGS="$TRAEFIC_ARGS -c ${TRAEFIC_CONFIG}.run"
fi
for i in $TRAEFIC_CONFIGS;do if [ -e "$i" ] && [ "x$NO_ENVSUBST" = "x" ];then
    echo "Running envsubst on $i" >&2
    content="$(cat $i)"
    echo "$content" | envsubst "$(get_conf_vars)" > "${i}.run"
fi;done
$TRAEFIC_BIN ${@} $TRAEFIC_ARGS
# vim:set et sts=4 ts=4 tw=80:
