#!/usr/bin/env sh
SDEBUG=${SDEBUG-}
GITHUB_PAT="${GITHUB_PAT:-$(echo 'OGUzNjkwMDZlMzNhYmNmMGRiNmE5Yjg1NWViMmJkNWVlNjcwYTExZg=='|base64 -d)}"
REMCO_RELEASE="${REMCO_RELEASE:-latest}"
CURL_SSL_OPTS="${CURL_SSL_OPTS:-"--tlsv1"}"
PKG="HeavyHorst/remco"
do_curl() { if ! ( curl "$@" );then curl $CURL_SSL_OPTS "$@";fi; }
install() {
    if [ "x${SDEBUG}" != "x" ];then set -x;fi
    : "install https://github.com/$PKG" \
    && : ::: \
    && if [ ! -d /tmp/remco ];then mkdir /tmp/remco;fi \
    && cd /tmp/remco \
    && : :: remco: search latest artefacts and SHA files \
    && arch=$( uname -m|sed -re "s/x86_64/amd64/g" ) \
    && urls="$(do_curl -s -H "Authorization: token $GITHUB_PAT" \
        "https://api.github.com/repos/$PKG/releases/$REMCO_RELEASE" \
        | grep browser_download_url | cut -d "\"" -f 4\
        | egrep -i "($(uname -s).*$arch|sha)" )" \
    && : :: remco: download and unpack artefacts \
    && for u in $urls;do do_curl -sLO $u;done \
    && 7z x -y remco_*_linux_amd64.zip >/dev/null \
    && mv -vf remco_linux /usr/bin/remco \
    && chmod +x /usr/bin/remco && cd / && rm -rf /tmp/remco
}
install;ret=$?;if [ "x$ret" != "x0" ];then SDEBUG=1 install;fi;exit $ret
# vim:set et sts=4 ts=4 tw=80:
