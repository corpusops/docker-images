#!/usr/bin/env sh
SDEBUG=${SDEBUG-}
GITHUB_PAT="${GITHUB_PAT:-$(echo 'OGUzNjkwMDZlMzNhYmNmMGRiNmE5Yjg1NWViMmJkNWVlNjcwYTExZg=='|base64 -d)}"
REMCO_RELEASE="${REMCO_RELEASE:-latest}"
CURL_SSL_OPTS="${CURL_SSL_OPTS:-"--tlsv1"}"
# original but does not work on alpine
PKG="corpusops/frep"
PKG="subchen/frep"
do_curl() { if ! ( curl "$@" );then curl $CURL_SSL_OPTS "$@";fi; }
install() {
    if [ "x${SDEBUG}" != "x" ];then set -x;fi
    : "install https://github.com/$PKG" \
    && : ::: \
    && if [ ! -d /tmp/frep ];then mkdir /tmp/frep;fi \
    && cd /tmp/frep \
    && : :: frep: search latest artefacts and SHA files \
    && arch=$( uname -m|sed -re "s/x86_64/amd64/g" ) \
    && urls="$(do_curl -s -H "Authorization: token $GITHUB_PAT" \
        "https://api.github.com/repos/$PKG/releases/$REMCO_RELEASE" \
        | grep browser_download_url | cut -d "\"" -f 4\
        | egrep -i "($(uname -s).*$arch|sha)" )" \
    && : :: frep: download and unpack artefacts \
    && for u in $urls;do do_curl -sLO $u;done \
    && sha256sum -c frep-*-linux-$arch.sha256 >/dev/nulm 2>&1 \
    && mv -vf frep*-linux*$arch /usr/bin/frep \
    && chmod +x /usr/bin/frep && cd / && rm -rf /tmp/frep
}
install;ret=$?;if [ "x$ret" != "x0" ];then SDEBUG=1 install;fi;exit $ret
# vim:set et sts=4 ts=4 tw=80:
