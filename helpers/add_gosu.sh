#!/usr/bin/env sh
set -x
GOSU_RELEASE="${GOSU_RELEASE:-latest}"
: install gosu \
    && : ::: \
    && mkdir /tmp/gosu && cd /tmp/gosu \
    && : :: gosu: search latest artefacts and SHA files \
    && arch=$( uname -m|sed -re "s/x86_64/amd64/g" ) \
    && : one keyserver may fail, try on multiple servers \
    && for k in $GPG_KEYS;do \
        touch /k_$k \
        && for s in $GPG_KEYS_SERVERS;do \
          if ( gpg --batch --keyserver $s --recv-keys $k );then \
            rm -f /k_$k && break;else echo "Keyserver failed: $s" >&2;fi;done \
        && if [ -e /k_$k ];then exit 1;fi \
       done \
    && urls="$( curl -s "https://api.github.com/repos/tianon/gosu/releases/$GOSU_RELEASE" \
               | grep browser_download_url | cut -d "\"" -f 4\
               | egrep -i "sha|$arch"; )" \
    && : :: gosu: download artefacts \
    && for u in $urls;do curl -sLO $u;done \
    && : :: gosu: integrity check \
    && for i in SHA256SUMS gosu-$arch;do gpg --batch --verify $i.asc $i &> /dev/null;done \
    && grep gosu-$arch SHA256SUMS | sha256sum -c - >/dev/null \
    && : :: gosu: filesystem install \
    && mv -f gosu-$arch /usr/bin/gosu \
    && chmod +x /usr/bin/gosu && cd / && rm -rf /tmp/gosu
# vim:set et sts=4 ts=4 tw=80:
