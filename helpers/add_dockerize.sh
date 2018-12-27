#!/usr/bin/env sh
SDEBUG=${SDEBUG-}
GITHUB_PAT="${GITHUB_PAT:-$(echo 'OGUzNjkwMDZlMzNhYmNmMGRiNmE5Yjg1NWViMmJkNWVlNjcwYTExZg=='|base64 -d)}"
DOCKERIZE_RELEASE="${DOCKERIZE_RELEASE:-latest}"
CURL_SSL_OPTS="--tlsv1"
install() {
    if [ "x${SDEBUG}" != "x" ];then set -x;fi
    : "install https://github.com/jwilder/dockerize" \
    && : ::: \
    && if [ ! -d /tmp/dockerize ];then mkdir /tmp/dockerize;fi \
    && cd /tmp/dockerize \
    && : :: dockerize: search latest artefacts and SHA files \
    && arch=$( uname -m|sed -re "s/x86_64/amd64/g" ) \
    && urls="$(curl -s ${CURL_SSL_OPTS} -H "Authorization: token $GITHUB_PAT" \
        "https://api.github.com/repos/jwilder/dockerize/releases/$DOCKERIZE_RELEASE" \
        | grep browser_download_url | cut -d "\"" -f 4\
        | ( if [ -e /etc/alpine-release ];then grep alpine;else grep -v alpine;fi; ) \
        | egrep -i "($(uname -s).*$arch|sha)" )" \
    && : :: dockerize: download and unpack artefacts \
    && for u in $urls;do curl ${CURL_SSL_OPTS} -sLO $u && tar -xzf $(basename $u);done \
    && mv -vf dockerize /usr/bin/dockerize \
    && chmod +x /usr/bin/dockerize && cd / && rm -rf /tmp/dockerize
}
install;ret=$?;if [ "x$ret" != "x0" ];then SDEBUG=1 install;fi;exit $ret
# vim:set et sts=4 ts=4 tw=80:
