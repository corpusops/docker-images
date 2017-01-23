#!/usr/bin/env sh
SDEBUG=${SDEBUG-}
GITHUB_PAT="${GITHUB_PAT:-$(echo 'OGUzNjkwMDZlMzNhYmNmMGRiNmE5Yjg1NWViMmJkNWVlNjcwYTExZg=='|base64 -d)}"
REMCO_RELEASE="${REMCO_RELEASE:-latest}"
CURL_SSL_OPTS="${CURL_SSL_OPTS:-"--tlsv1"}"
# original but does not work on alpine
PKG="corpusops/frep"
PKG="subchen/frep"
COPS_HELPERS=${COPS_HELPERS:-/cops_helpers}
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
        | grep -E -i "($(uname -s).*$arch|sha)" )" \
    && : :: frep: download and unpack artefacts \
    && for u in $urls;do do_curl -sLO $u;done \
    && echo $(cat frep-*-linux-$arch.sha256|awk '{print $1}'; ls frep-*-linux-$arch )|sed "s/ /  /g" > frep-*-linux-$arch.sha256.v \
    && sha256sum -wc frep-*-linux-$arch.sha256.v >/dev/null 2>&1 \
    && if [ ! -e $COPS_HELPERS ];then mkdir -p "$COPS_HELPERS";fi \
    && ln -sfv $COPS_HELPERS/frep /usr/bin \
    && mv -vf frep*-linux*$arch $COPS_HELPERS/frep \
    && chmod +x $COPS_HELPERS/frep && cd / && rm -rf /tmp/frep
}
install;ret=$?;if [ "x$ret" != "x0" ];then SDEBUG=1 install;fi;exit $ret
# vim:set et sts=4 ts=4 tw=0:
