#!/usr/bin/env sh
SDEBUG=${SDEBUG-}
GITHUB_PAT="${GITHUB_PAT:-$(echo 'OGUzNjkwMDZlMzNhYmNmMGRiNmE5Yjg1NWViMmJkNWVlNjcwYTExZg=='|base64 -d)}"
GOSU_RELEASE="${GOSU_RELEASE:-latest}"
CURL_SSL_OPTS="--tlsv1"
GOSU_GPG_KEYS="${GOSU_GPG_KEYS:-B42F6819007F00F88E364FD4036A9C25BF357DD4}"
GPG_KEYS_SERVERS="${GPG_KEYS_SERVERS:-"https://pgp.key-server.io/ hkp://p80.pool.sks-keyservers.net:80 hkp://ipv4.pool.sks-keyservers.net hkp://keyserver.ubuntu.com:80 hkp://pgp.mit.edu:80"}"
install() {
    if [ "x${SDEBUG}" != "x" ];then set -x;fi
    : install gosu \
    && : ::: \
    && if [ ! -d /tmp/gosu ];then mkdir /tmp/gosu;fi \
    && cd /tmp/gosu \
    && : :: gosu: search latest artefacts and SHA files \
    && arch=$( uname -m|sed -re "s/x86_64/amd64/g" ) \
    && : one keyserver may fail, try on multiple servers \
    && for k in $GOSU_GPG_KEYS;do \
        touch /k_$k \
        && for s in $GPG_KEYS_SERVERS;do \
          if ( gpg --batch --keyserver $s --recv-keys $k );then \
            rm -f /k_$k && break;else echo "Keyserver failed: $s" >&2;fi;done \
        && if [ -e /k_$k ];then exit 1;fi \
       done \
    && urls="$(curl ${CURL_SSL_OPTS} -s -H "Authorization: token $GITHUB_PAT" \
        "https://api.github.com/repos/tianon/gosu/releases/$GOSU_RELEASE" \
               | grep browser_download_url | cut -d "\"" -f 4\
               | egrep -i "sha|$arch"; )" \
    && : :: gosu: download artefacts \
    && for u in $urls;do curl ${CURL_SSL_OPTS} -sLO $u;done \
    && : :: gosu: integrity check \
    && for i in SHA256SUMS gosu-$arch;do
        if ! ( gpg --batch --verify $i.asc $i &> /dev/null );then
            gpg --batch --verify $i.asc $i
        fi
       done \
    && grep gosu-$arch SHA256SUMS | sha256sum -c - >/dev/null \
    && : :: gosu: filesystem install \
    && mv -vf gosu-$arch /usr/bin/gosu \
    && chmod +x /usr/bin/gosu && cd / && rm -rf /tmp/gosu
}
install;ret=$?;if [ "x$ret" != "x0" ];then SDEBUG=1 install;fi;exit $ret
# vim:set et sts=4 ts=4 tw=0:
