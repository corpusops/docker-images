#!/usr/bin/env sh
set -x
FOREGO_RELEASE="${FOREGO_RELEASE:-latest}"
: install forego \
    && : ::: \
    && mkdir /tmp/forego && cd /tmp/forego \
    && : :: forego: search latest artefacts and SHA files \
    && urls="$( curl -s \
      "https://api.github.com/repos/corpusops/forego/releases/$FOREGO_RELEASE" \
      | grep browser_download_url | cut -d "\"" -f 4; )" \
    && : :: forego: download artefacts \
    && for u in $urls;do curl -sLO $u;done \
    && : :: forego: integrity check \
    && grep forego.gz forego.gz.sha | sha256sum -c - >/dev/null \
    && : :: forego: filesystem install \
    && gunzip forego.gz && mv -f forego /usr/bin/forego \
    && chmod +x /usr/bin/forego && cd / && rm -rf /tmp/forego
# vim:set et sts=4 ts=4 tw=80:
