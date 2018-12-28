#!/usr/bin/env sh
SDEBUG=${SDEBUG-}
GITHUB_PAT="${GITHUB_PAT:-$(echo 'OGUzNjkwMDZlMzNhYmNmMGRiNmE5Yjg1NWViMmJkNWVlNjcwYTExZg=='|base64 -d)}"
FOREGO_RELEASE="${FOREGO_RELEASE:-latest}"
CURL_SSL_OPTS="${CURL_SSL_OPTS:-"--tlsv1"}"
do_curl() { if ! ( curl "$@" );then curl $CURL_SSL_OPTS "$@";fi; }
install () {
    if [ "x${SDEBUG}" != "x" ];then set -x;fi
: install forego \
    && : ::: \
    && if [ ! -d /tmp/forego ];then mkdir /tmp/forego;fi \
    && cd /tmp/forego \
    && : :: forego: search latest artefacts and SHA files \
    && urls="$(do_curl -s -H "Authorization: token $GITHUB_PAT" \
      "https://api.github.com/repos/corpusops/forego/releases/$FOREGO_RELEASE" \
      | grep browser_download_url | cut -d "\"" -f 4; )" \
    && : :: forego: download artefacts \
    && for u in $urls;do do_curl -sLO $u;done \
    && : :: forego: integrity check \
    && grep forego.gz forego.gz.sha | sha256sum -c - >/dev/null \
    && : :: forego: filesystem install \
    && gunzip forego.gz && mv -vf forego /usr/bin/forego \
    && chmod +x /usr/bin/forego && cd / && rm -rf /tmp/forego
}
install;ret=$?;if [ "x$ret" != "x0" ];then SDEBUG=1 install;fi;exit $ret
# vim:set et sts=4 ts=4 tw=80:
