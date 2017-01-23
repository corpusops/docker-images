#!/usr/bin/env sh
SDEBUG=${SDEBUG-}
GITHUB_PAT="${GITHUB_PAT:-$(echo 'OGUzNjkwMDZlMzNhYmNmMGRiNmE5Yjg1NWViMmJkNWVlNjcwYTExZg=='|base64 -d)}"
GOSU_RELEASE="${GOSU_RELEASE:-latest}"
CURL_SSL_OPTS="${CURL_SSL_OPTS:-"--tlsv1"}"
GOSU_GPG_KEYS="${GOSU_GPG_KEYS:-B42F6819007F00F88E364FD4036A9C25BF357DD4}"
GPG_KEYS_SERVERS="${GPG_KEYS_SERVERS:-"hkp://p80.pool.sks-keyservers.net:80 hkp://ipv4.pool.sks-keyservers.net hkp://keyserver.ubuntu.com:80 hkp://pgp.mit.edu:80"}"
COPS_HELPERS=${COPS_HELPERS:-/cops_helpers}
do_curl() { if ! ( curl "$@" );then curl $CURL_SSL_OPTS "$@";fi; }
install() {
    if [ "x${SDEBUG}" != "x" ];then set -x;fi
    : install gosu \
    && : ::: \
    && if [ ! -d /tmp/gosu ];then mkdir /tmp/gosu;fi \
    && cd /tmp/gosu \
    && : :: gosu: search latest artefacts and SHA files \
    && arch=$( uname -m|sed -re "s/x86_64/amd64/g" ) \
    && urls="$(do_curl -s -H "Authorization: token $GITHUB_PAT" \
        "https://api.github.com/repos/tianon/gosu/releases/$GOSU_RELEASE" \
               | grep browser_download_url | cut -d "\"" -f 4\
               | grep -E -i "sha|$arch"; )" \
    && : :: gosu: download artefacts \
    && for u in $urls;do do_curl -sLO $u;done \
    && : :: gosu: integrity check \
    && grep gosu-$arch SHA256SUMS | sha256sum -c - >/dev/null \
    && : :: gosu: filesystem install \
    && if [ ! -e $COPS_HELPERS ];then mkdir -p "$COPS_HELPERS";fi \
    && ln -sfv $COPS_HELPERS/gosu /usr/bin \
    && mv -vf gosu-$arch $COPS_HELPERS/gosu \
    && chmod +x $COPS_HELPERS/gosu && cd / && rm -rf /tmp/gosu
}
install;ret=$?;if [ "x$ret" != "x0" ];then SDEBUG=1 install;fi;exit $ret
# vim:set et sts=4 ts=4 tw=0:
