#!/usr/bin/env sh
SDEBUG=${SDEBUG-}
GITHUB_PAT="${GITHUB_PAT:-$(echo 'OGUzNjkwMDZlMzNhYmNmMGRiNmE5Yjg1NWViMmJkNWVlNjcwYTExZg=='|base64 -d)}"
DOCKERIZE_RELEASE="${DOCKERIZE_RELEASE:-latest}"
CURL_SSL_OPTS="${CURL_SSL_OPTS:-"--tlsv1"}"
COPS_HELPERS=${COPS_HELPERS:-/cops_helpers}
do_curl() { if ! ( curl "$@" );then curl $CURL_SSL_OPTS "$@";fi; }
install() {
    if [ "x${SDEBUG}" != "x" ];then set -x;fi
    : "install https://github.com/jwilder/dockerize" \
    && : ::: \
    && if [ ! -d /tmp/dockerize ];then mkdir /tmp/dockerize;fi \
    && cd /tmp/dockerize \
    && : :: dockerize: search latest artefacts and SHA files \
    && arch=$( uname -m|sed -re "s/x86_64/amd64/g" ) \
    && urls="$(do_curl -s -H "Authorization: token $GITHUB_PAT" \
        "https://api.github.com/repos/jwilder/dockerize/releases/$DOCKERIZE_RELEASE" \
        | grep browser_download_url | cut -d "\"" -f 4\
        | ( if [ -e /etc/alpine-release ];then grep alpine;else grep -v alpine;fi; ) \
        | egrep -i "($(uname -s).*$arch|sha)" )" \
    && : :: dockerize: download and unpack artefacts \
    && for u in $urls;do do_curl -sLO $u && tar -xzf $(basename $u);done \
    && if [ ! -e $COPS_HELPERS ];then mkdir -p "$COPS_HELPERS";fi \
    && ln -sfv $COPS_HELPERS/dockerize /usr/bin \
    && mv -vf dockerize $COPS_HELPERS/dockerize \
    && chmod +x $COPS_HELPERS/dockerize && cd / && rm -rf /tmp/dockerize
}
install;ret=$?;if [ "x$ret" != "x0" ];then SDEBUG=1 install;fi;exit $ret
# vim:set et sts=4 ts=4 tw=80:
