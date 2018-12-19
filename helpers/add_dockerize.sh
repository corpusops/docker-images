#!/usr/bin/env sh
set -x
DOCKERIZE_RELEASE="${DOCKERIZE_RELEASE:-latest}"
: "install https://github.com/jwilder/dockerize" \
    && : ::: \
    && mkdir /tmp/dockerize && cd /tmp/dockerize \
    && : :: dockerize: search latest artefacts and SHA files \
    && arch=$( uname -m|sed -re "s/x86_64/amd64/g" ) \
    && urls="$(curl -s \
        "https://api.github.com/repos/jwilder/dockerize/releases/$DOCKERIZE_RELEASE" \
        | grep browser_download_url | cut -d "\"" -f 4\
        | ( if [ -e /etc/alpine-release ];then grep alpine;else grep -v alpine;fi; ) \
        | egrep -i "($(uname -s).*$arch|sha)" )" \
    && : :: dockerize: download and unpack artefacts \
    && for u in $urls;do curl -sLO $u && tar -xf $(basename $u);done \
    && mv -f dockerize /usr/bin/dockerize \
    && chmod +x /usr/bin/dockerize && cd / && rm -rf /tmp/dockerize
# vim:set et sts=4 ts=4 tw=80:
