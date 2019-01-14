#!/usr/bin/env sh
# $ CONF_PREFIX=FOO__ confenvsubst.sh my.config
# $ ENVSUBST_DEST=/aggregatedconfig CONF_PREFIX=FOO__ confenvsubst.sh my.cfg my.ocfg
#
# $ echo '$FOO__BAR' | CONF_PREFIX=FOO__ confenvsubst.sh > configfile
# $ echo '$FOO__BAR' | ENVSUBST_DEST=configfile CONF_PREFIX=FOO__ confenvsubst.sh
# override mode:
# $ echo '$FOO__BAR' | ENVSUBST_MODE="" ENVSUBST_DEST=configfile CONF_PREFIX=FOO__ confenvsubst.sh
#
set -e
CONF_PREFIX="${CONF_PREFIX:-CONFIG__}"
CONF_VARS="${CONF_VARS-}"
get_conf_vars() {
    echo $( env | egrep "^${CONF_PREFIX}[^=]+=.*" \
            | sed -re "s/((^${CONF_PREFIX})[^=]+)=.*/$\1;/g";); }
doenvsubst() {
    substsuf=""
    if [ "x${1-}" ];then substsuf=": $@";fi
    confvars="$CONF_VARS"
    if [ "x$CONF_VARS" != "x" ];then
        confvars="$CONF_VARS;$(get_conf_vars)"
    else
        confvars=$(get_conf_vars)
    fi
    tlog="Running envsubst${substsuf}"
    if [ "x$confvars" != "x" ];then tlog="$tlog ($confvars)";fi
    echo "$tlog" >&2
    envsubst "$confvars"
}
SDEBUG=${SDEBUG-}
TEMPLATE_SUFFIXES="\.(in|template|envsubst)$"
ENVSUBST_DEST="${ENVSUBST_DEST-}"
if [ "x$ENVSUBST_DEST" = "x" ];then
    DEFAULT_ENVSUBST_MODE=""
else
    DEFAULT_ENVSUBST_MODE="concat"
fi
ENVSUBST_MODE=${ENVSUBST_MODE:-$DEFAULT_ENVSUBST_MODE}
NO_ENVSUBST=${NO_ENVSUBST-}
NO_TEMPLATE=${NO_TEMPLATE-}
if [ "x$NO_ENVSUBST" != "x" ];then exit 0;fi
if [ "x$SDEBUG" != "x" ];then set -x;fi
if [ "x$ENVSUBST_DEST" != "x" ];then touch "$ENVSUBST_DEST";fi
if [ "x${1-}" != "x" ];then
    for i in $@;do if [ -e "$i" ];then
        dest="$ENVSUBST_DEST"
        if [ "x$ENVSUBST_DEST" = "x" ];then
            dest="$i"
            if [ "x${NO_TEMPLATE}" = "x" ];then
                dest=$(echo "$i"|sed -re "s/$TEMPLATE_SUFFIXES//g")
            fi
            if [ "x${dest}" != "x$i" ];then cp -p "$i" "$dest";fi
        fi
        content="$(cat $i)"
        if [ ! -e $(dirname "$dest") ];then
            mkdir -p "$(dirname $ENVSUBST_DEST)"
        fi
        if [ "x$ENVSUBST_MODE" = "xconcat" ];then
            echo "$content"|doenvsubst "$i concat -> dest: $dest" >> "$dest"
        else
            echo "$content"|doenvsubst "$i -> dest: $dest" > "$dest"
        fi
    fi;done
else
    if [ "x$ENVSUBST_DEST" != "x" ];then
        if [ "x$ENVSUBST_MODE" = "xconcat" ];then
            doenvsubst "STDIN concat -> $ENVSUBST_DEST" >> "$ENVSUBST_DEST"
        else
            doenvsubst "STDIN -> $ENVSUBST_DEST" > "$ENVSUBST_DEST"
        fi
    else
        doenvsubst "STDIN"
    fi
fi
# vim:set et sts=4 ts=4 tw=0:
