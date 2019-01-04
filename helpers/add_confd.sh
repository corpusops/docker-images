#!/usr/bin/env sh
SDEBUG=${SDEBUG-}
GITHUB_PAT="${GITHUB_PAT:-$(echo 'OGUzNjkwMDZlMzNhYmNmMGRiNmE5Yjg1NWViMmJkNWVlNjcwYTExZg=='|base64 -d)}"
CONFD_RELEASE="${CONFD_RELEASE:-latest}"
CURL_SSL_OPTS="${CURL_SSL_OPTS:-"--tlsv1"}"
do_curl() { if ! ( curl "$@" );then curl $CURL_SSL_OPTS "$@";fi; }
install() {
    if [ "x${SDEBUG}" != "x" ];then set -x;fi
    : "install https://github.com/kelseyhightower/confd" \
    && : ::: \
    && if [ ! -d /tmp/confd ];then mkdir /tmp/confd;fi \
    && cd /tmp/confd \
    && : :: confd: search latest artefacts and SHA files \
    && arch=$( uname -m|sed -re "s/x86_64/amd64/g" ) \
    && urls="$(do_curl -s -H "Authorization: token $GITHUB_PAT" \
        "https://api.github.com/repos/kelseyhightower/confd/releases/$CONFD_RELEASE" \
        | grep browser_download_url | cut -d "\"" -f 4\
        | egrep -i "($(uname -s).*$arch|sha)" )" \
    && : :: confd: download and unpack artefacts \
    && for u in $urls;do do_curl -sLO $u;done \
    && mv -vf confd* /usr/bin/confd \
    && chmod +x /usr/bin/confd && cd / && rm -rf /tmp/confd
}
install;ret=$?;if [ "x$ret" != "x0" ];then SDEBUG=1 install;fi;exit $ret
# vim:set et sts=4 ts=4 tw=80:
