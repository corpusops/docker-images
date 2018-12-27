#!/usr/bin/env bash
set -e
shopt -s extglob
## refresh from corpsusops.bootstrap/hacking/shell_glue (copy paste until last function)
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
# colors
RED="\\e[0;31m"
CYAN="\\e[0;36m"
YELLOW="\\e[0;33m"
NORMAL="\\e[0;0m"
NO_COLOR=${NO_COLORS-${NO_COLORS-${NOCOLOR-${NOCOLORS-}}}}
LOGGER_NAME=${LOGGER_NAME:-corpusops_build}
ERROR_MSG="There were errors"
uniquify_string() {
    local pattern=$1
    shift
    echo "$@" \
        | sed -e "s/${pattern}/\n/g" \
        | awk '!seen[$0]++' \
        | tr "\n" "${pattern}" \
        | sed -e "s/^${pattern}\|${pattern}$//g"
}
do_trap_() { rc=$?;func=$1;sig=$2;${func};if [ "x${sig}" != "xEXIT" ];then kill -${sig} $$;fi;exit $rc; }
do_trap() { rc=${?};func=${1};shift;sigs=${@};for sig in ${sigs};do trap "do_trap_ ${func} ${sig}" "${sig}";done; }
is_ci() { return $( set +e;( [ "x${TRAVIS-}" != "x" ] || [ "x${GITLAB_CI}" != "x" ] );echo $?; ); }
log_() {
    reset_colors;msg_color=${2:-${YELLOW}};
    logger_color=${1:-${RED}};
    logger_slug="${logger_color}[${LOGGER_NAME}]${NORMAL} ";
    shift;shift;
    if [ "x${NO_LOGGER_SLUG}" != "x" ];then logger_slug="";fi
    printf "${logger_slug}${msg_color}$(echo "${@}")${NORMAL}\n" >&2;
    printf "" >&2;  # flush
}
reset_colors() { if [ "x${NO_COLOR}" != "x" ];then BLUE="";YELLOW="";RED="";CYAN="";fi; }
log() { log_ "${RED}" "${CYAN}" "${@}"; }
get_chrono() { date "+%F_%H-%M-%S"; }
cronolog() { log_ "${RED}" "${CYAN}" "($(get_chrono)) ${@}"; }
debug() { if [ "x${DEBUG-}" != "x" ];then log_ "${YELLOW}" "${YELLOW}" "${@}"; fi; }
warn() { log_ "${RED}" "${CYAN}" "${YELLOW}[WARN] ${@}${NORMAL}"; }
bs_log(){ log_ "${RED}" "${YELLOW}" "${@}"; }
bs_yellow_log(){ log_ "${YELLOW}" "${YELLOW}" "${@}"; }
may_die() {
    reset_colors
    thetest=${1:-1}
    rc=${2:-1}
    shift
    shift
    if [ "x${thetest}" != "x0" ]; then
        if [ "x${NO_HEADER-}" = "x" ]; then
            NO_LOGGER_SLUG=y log_ "" "${CYAN}" "Problem detected:"
        fi
        NO_LOGGER_SLUG=y log_ "${RED}" "${RED}" "$@"
        exit $rc
    fi
}
die() { may_die 1 1 "${@}"; }
die_in_error_() {
    ret=${1}; shift; msg="${@:-"$ERROR_MSG"}";may_die "${ret}" "${ret}" "${msg}";
}
die_in_error() { die_in_error_ "${?}" "${@}"; }
die_() { NO_HEADER=y die_in_error_ $@; }
sdie() { NO_HEADER=y die $@; }
parse_cli() { parse_cli_common "${@}"; }
parse_cli_common() {
    USAGE=
    for i in ${@-};do
        case ${i} in
            --no-color|--no-colors|--nocolor|--no-colors)
                NO_COLOR=1;;
            -h|--help)
                USAGE=1;;
            *) :;;
        esac
    done
    reset_colors
    if [ "x${USAGE}" != "x" ]; then
        usage
    fi
}
has_command() {
    ret=1
    if which which >/dev/null 2>/dev/null;then
      if which "${@}" >/dev/null 2>/dev/null;then
        ret=0
      fi
    else
      if command -v "${@}" >/dev/null 2>/dev/null;then
        ret=0
      else
        if hash -r "${@}" >/dev/null 2>/dev/null;then
            ret=0
        fi
      fi
    fi
    return ${ret}
}
pipe_return() {
    local filter=$1;shift;local command=$@;
    (((($command; echo $? >&3) | $filter >&4) 3>&1) | (read xs; exit $xs)) 4>&1;
}
output_in_error() { ( do_trap output_in_error_post EXIT TERM QUIT INT;\
                      output_in_error_ "${@}" ; ); }
output_in_error_() {
    if [ "x${OUTPUT_IN_ERROR_DEBUG-}" != "x" ];then set -x;fi
    if ( is_ci );then
        DEFAULT_CI_BUILD=y
    fi
    CI_BUILD="${CI_BUILD-${DEFAULT_CI_BUILD-}}"
    if [ "x$CI_BUILD" != "x" ];then
        DEFAULT_NO_OUTPUT=y
        DEFAULT_DO_OUTPUT_TIMER=y
    fi
    VERBOSE="${VERBOSE-}"
    TIMER_FREQUENCE="${TIMER_FREQUENCE:-120}"
    NO_OUTPUT="${NO_OUTPUT-${DEFAULT_NO_OUTPUT-1}}"
    DO_OUTPUT_TIMER="${DO_OUTPUT_TIMER-$DEFAULT_DO_OUTPUT_TIMER}"
    LOG=${LOG-}
    if [ "x$NO_OUTPUT" != "x" ];then
        if [  "x${LOG}" = "x" ];then
            LOG=$(mktemp)
            DEFAULT_CLEANUP_LOG=y
        else
            DEFAULT_CLEANUP_LOG=
        fi
    else
        DEFAULT_CLEANUP_LOG=
    fi
    CLEANUP_LOG=${CLEANUP_LOG:-${DEFAULT_CLEANUP_LOG}}
    if [ "x$VERBOSE" != "x" ];then
        log "Running$([ "x$LOG" != "x" ] && echo "($LOG)"; ): $@";
    fi
    TMPTIMER=
    if [ "x${DO_OUTPUT_TIMER}" != "x" ]; then
        TMPTIMER=$(mktemp)
        ( i=0;\
          while test -f $TMPTIMER;do\
           i=$((++i));\
           if [ `expr $i % $TIMER_FREQUENCE` -eq 0 ];then \
               log "BuildInProgress$( if [ "x$LOG" != "x" ];then echo "($LOG)";fi ): ${@}";\
             i=0;\
           fi;\
           sleep 1;\
          done;\
          if [ "x$VERBOSE" != "x" ];then log "done: ${@}";fi; ) &
    fi
    # unset NO_OUTPUT= LOG= to prevent output_in_error children to be silent
    # at first
    reset_env="NO_OUTPUT LOG"
    if [ "x$NO_OUTPUT" != "x" ];then
        ( unset $reset_env;"${@}" ) >>"$LOG" 2>&1;ret=$?
    else
        if [ "x$LOG" != "x" ] && has_command tee;then
            ( unset $reset_env; pipe_return "tee -a $tlog" "${@}"; )
            ret=$?
        else
            ( unset $reset_env; "${@}"; )
            ret=$?
        fi
    fi
    if [ -e "$TMPTIMER" ]; then rm -f "${TMPTIMER}";fi
    if [ "x${OUTPUT_IN_ERROR_NO_WAIT-}" = "x" ];then wait;fi
    if [ -e "$LOG" ] &&  [ "x${ret}" != "x0" ] && [ "x$NO_OUTPUT" != "x" ];then
        cat "$LOG" >&2
    fi
    if [ "x${OUTPUT_IN_ERROR_DEBUG-}" != "x" ];then set +x;fi
    return ${ret}
}
output_in_error_post() {
    if [ -e "$TMPTIMER" ]; then rm -f "${TMPTIMER}";fi
    if [ -e "$LOG" ] && [ "x$CLEANUP_LOG" != "x" ];then rm -f "$LOG";fi
}
test_silent_log() { ( [ "x${NO_SILENT-}" = "x" ] && ( [ "x${SILENT_LOG-}" != "x" ] || [ x"${SILENT_DEBUG}" != "x" ] ) ); }
test_silent() { ( [ "x${NO_SILENT-}" = "x" ] && ( [ "x${SILENT-}" != "x" ] || test_silent_log ) ); }
silent_run_() {
    (LOG=${SILENT_LOG:-${LOG}};
     NO_OUTPUT=${NO_OUTPUT-};\
     if test_silent;then NO_OUTPUT=y;fi;output_in_error "$@";)
}
silent_run() { ( silent_run_ "${@}" ; ); }
run_silent() {
    (
    DEFAULT_RUN_SILENT=1;
    if [ "x${NO_SILENT-}" != "x" ];then DEFAULT_RUN_SILENT=;fi;
    SILENT=${SILENT-DEFAULT_RUN_SILENT} silent_run "${@}";
    )
}
vvv() { debug "${@}";silent_run "${@}"; }
vv() { log "${@}";silent_run "${@}"; }
silent_vv() { SILENT=${SILENT-1} vv "${@}"; }
quiet_vv() { if [ "x${QUIET-}" = "x" ];then log "${@}";fi;run_silent "${@}";}
## end from glue
LOGGER_NAME="dockerimages-builder"
rc=0
THISSCRIPT=$0
W="$(dirname $(readlinkf $THISSCRIPT))"
cd "$W"
if [[ -n $SDEBUG ]];then set -x;fi
DOCKER_REPO=${DOCKER_REPO:-corpusops}
TOPDIR=$(pwd)
SDEBUG=${SDEBUG-}
DEBUG=${DEBUG-}
DRYRUN=${DRYRUN-}
NOREFRESH=${NOREFRESH-}
NBPARALLEL=${NBPARALLEL-4}
SKIP_MINOR="((node|ruby|php|golang|python|mysql|postgres|solr|elasticsearch|mongo|ruby):.*([0-9]\.?){3})"
SKIP_PRE="((node|ruby|postgres|solr|elasticsearch|mongo|php|golang):.*(alpha|beta|rc))"
SKIP_OS="((suse|centos|fedora|redhat|alpine|debian|ubuntu):.*[0-9]{8}.*)"
SKIP_PHP="(php:(.*(RC|-rc-).*))"
SKIP_WINDOWS="(.*(nanoserver|windows))"
SKIPPED_TAGS="($SKIP_MINOR|$SKIP_PRE|$SKIP_OS|$SKIP_PHP|$SKIP_WINDOWS|-old$)"
CURRENT_TS=$(date +%s)
default_images="
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
library/solr
library/mongo
library/elasticsearch
makinacorpus/pgrouting
mdillon/postgis
"
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


#  refresh_images $args: refresh images files
#     refresh_images:  (no arg) refresh all images
#     refresh_images library/ubuntu: only refresh ubuntu images
do_refresh_images() {
    local images="${@:-$default_images}"
    while read image;do
        if [[ -n $image ]];then
            clean_tags $image
            make_tags $image
        fi
    done <<< "$images"
}

char_occurence() {
    local char=$1
    shift
    echo "$@" | awk -F"$char" '{print NF-1}'
}

record_build_image() {
    # library/ubuntu/latest / mdillion/postgis/latest
    local image=$1
    # ubuntu/latest / mdillion/postgis/latest
    local nimage=$(echo $image / sed -re "s/^library\///g")
    # corpusops
    local repo=$DOCKER_REPO
    # ubuntu / postgis
    local tag=$(basename $(dirname $image))
    # latest / latest
    local version=$(basename $image)
    local i=
    for i in $image $image/.. $image/../../..;do
        # ubuntu-bare / postgis
        if [ -e $i/repo ];then repo=$( cat $i/repo );break;fi
    done
    for i in $image $image/.. $image/../../..;do
        # ubuntu-bare / postgis
        if [ -e $i/tag ];then tag=$( cat $i/tag );break;fi
    done
    local df=${df:-Dockerfile}
    book="$(printf "docker build -t $repo/$tag:$version . -f $image/$df\n${book}")"
}

#  build $args: refresh images files
#     build:  (no arg) refresh all images
#     build library/ubuntu: only refresh ubuntu images
#     build library/ubuntu/latest: only refresh ubuntu:latest image
do_build() {
    local images="${@:-$default_images}"
    local to_build=""
    local i=
    for i in $images;do
        local number_of_slash=$( char_occurence / $i )
        if [ ! -e $i ];then
            sdie "$i: folder does not exist yet, use refresh_images ?"
        elif [ $number_of_slash = 1 ];then
            to_build="$to_build $(find $i -mindepth 1 -maxdepth 1 -type d|sed "s/^.\///g"|sort -V)"
        elif [ $number_of_slash = 2 ];then
            to_build="$to_build $i"
        else
            sdie "$i: invalid number or slash: $number_of_slash"
        fi
    done
    local counter=0
    local book=""
    for i in $to_build;do
        record_build_image $i
        counter=$((counter+1))
    done
    book=$( echo "$book"|tac|awk '!seen[$0]++' )
    if [[ -n $book ]];then
        if [ $NBPARALLEL -gt 1 ];then
            if ! ( has_command parallel );then
                die "install Gnu parallel (package: parrallel on most distrib)"
            fi
            if ! ( echo "$book" | parallel --joblog build.log -j$NBPARALLEL --tty $( [[ -n $DRYRUN ]] && echo "--dry-run" ); );then
                if [ -e build.log ];then cat build.log;fi
                rc=124
            fi
        else
            while read cmd;do
                if [[ -n $cmd ]];then
                    if ! (  $( [[ -n $DRYRUN ]] && echo "log Would run:" || echo "vv" ) $cmd );then rc=123;fi
                fi
            done <<< "$book"
        fi
    fi
    return $rc
}


#  list_images: list images family
do_list_images() {
    for i in $(find -mindepth 2 -type d);do
        if [ -e "$i/Dockerfile" ];then echo "$i";fi
    done\
    | sed -re "s|(\./)?([^/]+/[^/]+)/.*|\2|g"\
    | awk '!seen[$0]++' | sort -V
}

#  gen_travis; regenerate .travis.yml file
do_gen_travis() {
    __images__="$(for i in $(do_list_images);do echo "  - IMAGES=$i";done;echo; )" \
        envsubst '$__images__' > "$W/.travis.yml" < "$W/.travis.yml.in"
}

#  gen: regenerate both images and travis.yml
do_gen() {
    if [[ -z "$NOREFRESH" ]];then do_refresh_images $@;fi
    do_gen_travis
}

#  usage: show this help
do_usage() {
    echo "$0:"
    # Show autodoc help
    awk '{ if ($0 ~ /^#[^!#]/) { \
                gsub(/^#/, "", $0); print $0 } }' \
                "$THISSCRIPT"|egrep -v "vim|^ colors"
    echo ""
}

do_main() {
    local args=${@:-usage}
    local actions="refresh_images|build|gen_travis|gen|list_images"
    actions="@($actions)"
    action=${1-};
    if [[ -n "$@" ]];then shift;fi
    case $action in
        $actions) do_$action $@;;
        *) do_usage;;
    esac
    exit $rc
}
cd "$W"
do_main "$@"
# vim:set et sts=4 ts=4 tw=80: