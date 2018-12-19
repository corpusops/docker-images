#!/usr/bin/env bash
set -e
rc=0
readlinkf() {
    if ( uname | egrep -iq "darwin|bsd" );then
        if ( which greadlink 2>&1 >/dev/null );then
            greadlink -f "$@"
        elif ( which perl 2>&1 >/dev/null );then
            perl -MCwd -le 'print Cwd::abs_path shift' "$@"
        elif ( which python 2>&1 >/dev/null );then
            python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$@"
        fi
    else
        readlink -f "$@"
    fi
}
cd "$(dirname $(readlinkf "$0"))"
DOCKER_REPO=${DOCKER_REPO:-corpusops}
TOPDIR=$(pwd)
SDEBUG=${SDEBUG-}
DEBUG=${DEBUG-}


SKIP_MINOR="((node|ruby|php|golang|python|mysql|postgres|ruby):.*([0-9]\.?){3})"
SKIP_PRE="((node|ruby|postgres|php|golang):.*(alpha|beta|rc))"
SKIP_OS="((suse|centos|fedora|redhat|alpine|debian|ubuntu):.*[0-9]{8}.*)"
SKIP_PHP="(php:(.*(RC|-rc-).*))"
SKIP_WINDOWS="(.*(nanoserver|windows))"
SKIPPED_TAGS="($SKIP_MINOR|$SKIP_PRE|$SKIP_OS|$SKIP_PHP|$SKIP_WINDOWS|-old$)"
CURRENT_TS=$(date +%s)
if [[ -n $SDEBUG ]];then set -x;fi
# find library/  makinacorpus/ mdillon/  -mindepth 1 -maxdepth 1 -type d | sort -n
images=${@:-"
library/alpine
library/centos
library/debian
library/fedora
library/golang
library/mysql
library/nginx
library/node
library/php
library/postgres
library/python
library/ruby
library/ubuntu
library/opensuse
makinacorpus/pgrouting
mdillon/postgis
"}

log() { echo "$@">&2; }
debug() { if [[ -n $DEBUG ]];then log "$@";fi }

gen_image() {
    local image=$1 tag=$2
    local ldir="$TOPDIR/$image/$tag"
    local system=apt
    local dockeriles=""
    if [ ! -e "$ldir" ];then mkdir -p "$ldir";fi
    cd "$ldir"
    if ( echo "$image $tag"|egrep -iq "redhat|centos|oracle|fedora|red-hat" );then
        system=redhat
    elif ( echo "$image $tag"|egrep -iq suse );then
        system=suse
    elif ( echo "$image $tag"|egrep -iq alpine );then
        system=alpine
    fi
    IMG=$image
    if [ -e ../tag ];then
        IMG=$(cat ../tag )
    fi
    export BASE=$image
    export SYSTEM=$system
    export VERSION=$tag
    export IMG=$DOCKER_REPO/$(basename $IMG)
    debug "IMG: $IMG | SYSTEM: $SYSTEM | BASE: $image | VERSION: $VERSION"
    for folder in . .. ../../..;do
        local df="$folder/Dockerfile.override"
        if [ -e "$df" ];then dockerfiles="$dockerfiles $df" && break;fi
    done
    for order in from args argspost helpers pre base post clean cleanpost;do
        for folder in . .. ../../..;do
            local df="$folder/Dockerfile.$order"
            if [ -e "$df" ];then dockerfiles="$dockerfiles $df" && break;fi
        done
    done
    if [[ -z $dockerfiles ]];then
        log "no dockerfile for $image"
        rc=1
        return $rc
    else
        debug "Using dockerfiles: $dockerfiles from $image"
    fi
    cat $dockerfiles | envsubst '$BASE;$VERSION;$SYSTEM' > Dockerfile
    cd - &>/dev/null
}

get_image_tags() {
    set +e
    local n=$1
    local results="" result=""
    local i=0
    local has_more=0
    local t="$TOPDIR/$n/imagetags"
    local u="https://registry.hub.docker.com/v2/repositories/${n}/tags/"
    local last_modified=$(stat -c "%Y" "$t" 2>/dev/null )
    if [ -e "$t" ] && [ $(($CURRENT_TS-$last_modified)) -lt $((24*60*60)) ];then
        has_more=1
    fi
    if [ $has_more -eq 0 ];then
        while [ $has_more -eq 0 ];do
            i=$((i+1))
            result=$( curl "${u}?page=${i}" 2>/dev/null \
                | jq -r '."results"[]["name"]' 2>/dev/null )
            has_more=$?
            if [[ -n "${result}}" ]];then results="${results} ${result}";fi
        done
        rm -f "$t.raw"
        if [ ! -e "$TOPDIR/$n" ];then mkdir -p "$TOPDIR/$n";fi
        printf "$results\n" > "$t.raw"
    fi
    rm -f "$t"
    ( for i in $(cat "$t.raw");do
        if ! ( echo "$n:$i" | egrep -q "$SKIPPED_TAGS" );then printf "$i\n"; fi
      done | awk '!seen[$0]++' ) >> "$t"
    set -e
    if [ -e "$t" ];then cat "$t";fi
}

make_tags() {
    local image=$1
    log "Operating on $image"
    local tags=$(get_image_tags $image )
    debug "image: $image tags: $( echo $tags )"
    for t in $tags;do if ! ( gen_image "$image" "$t"; );then rc=1;fi;done
}

clean_tags () {
    local image=$1
    log "Cleaning on $image"
    local tags=$(get_image_tags $image )
    debug "image: $image tags: $( echo $tags )"
    while read image;do
        local tag=$(basename $image)
        if ! ( echo "$tags" | egrep -q "^$tag$" );then
            rm -rfv "$image"
        fi
    done < <(find "$TOPDIR/$image" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
}

while read image;do
    if [[ -n $image ]];then
        clean_tags $image
        make_tags $image
    fi
done <<< "$images"
exit $rc
# vim:set et sts=4 ts=4 tw=80:
