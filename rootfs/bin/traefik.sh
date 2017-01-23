#!/usr/bin/env sh
set -e
CONF_PREFIX="${TRAEFIK_CONF_PREFIX:-${CONF_PREFIX:-TRAEFIK_}}"
get_conf_vars() {
    echo $( env | grep -E "${CONF_PREFIX}[^=]+=.*" \
            | sed -re "s/((${CONF_PREFIX})[^=]+)=.*/$\1;/g";); }
SDEBUG=${SDEBUG-}
if [ "x$SDEBUG" != "x" ];then set -x;fi
export NO_ENVSUBST=""
export TRAEFIK_CONFIGS=""
export TRAEFIK_BIN="${TRAEFIK_BIN:-"traefik"}"
export TRAEFIK_ARGS="${TRAEFIK_ARGS-}"
export TRAEFIK_DEFAULT_CONFIG=""
if ! ( echo "$@" |grep -E -q -- ' -c |--config' );then
    export TRAEFIK_DEFAULT_CONFIG="/traefik.toml"
fi
export TRAEFIK_CONFIG="${TRAEFIK_CONFIG:-${TRAEFIK_DEFAULT_CONFIG}}"
for e in $TRAEFIK_CONF_DIR;do if [ ! -e "$e" ];then mkdir -p "$e";fi;done
if [ -e "$TRAEFIK_CONFIG" ];then
    export TRAEFIK_CONFIGS="$TRAEFIK_CONFIGS $TRAEFIK_CONFIG"
    export TRAEFIK_ARGS="$TRAEFIK_ARGS -c ${TRAEFIK_CONFIG}.run"
fi
CONF_PREFIX="$TRAEFIK_CONF_PREFIX" confenvsubst.sh $TRAEFIK_CONFIGS
exec $TRAEFIK_BIN ${@} $TRAEFIK_ARGS
# vim:set et sts=4 ts=4 tw=80:
