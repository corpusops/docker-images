FROM library/node:9.4
ARG DO_UPDATE=y
ARG NONINTERACTIVE=y
ARG GPG_KEYS=B42F6819007F00F88E364FD4036A9C25BF357DD4
ARG GPG_KEYS_SERVERS="https://pgp.key-server.io/ hkp://p80.pool.sks-keyservers.net:80 hkp://ipv4.pool.sks-keyservers.net hkp://keyserver.ubuntu.com:80 hkp://pgp.mit.edu:80"
ARG INSTALL_DEFAULT_LOCALE="fr_FR.UTF-8"
ARG EXTRA_PACKAGES_LIST="packages/packages_apt.txt"
ARG FOREGO_RELEASE=latest
ARG GOSU_RELEASE=latest
ARG DOCKERIZE_RELEASE=latest
ADD \
    helpers/add_gosu.sh \
    helpers/add_dockerize.sh \
    helpers/setup_locales.sh \
    helpers/add_forego.sh \
    helpers/cops_pkgmgr_install.sh \
    helpers/apt_up.sh \
    packages/packages_apt.txt \
    ${EXTRA_PACKAGES_LIST} \
    /tmp/corpusopssteroids/
RUN sh -c 'set -ex \
    && cd /tmp/corpusopssteroids \
    && chmod +x *sh \
    && cat packages_*.txt > apt.txt \
    && ./apt_up.sh \
    && cp -v cops_pkgmgr_install.sh /bin \
    && DEBUG=1 ./setup_locales.sh \
    && ./add_dockerize.sh \
    && ./add_gosu.sh \
    && ./add_forego.sh \
    '
ADD helpers/apt_clean.sh /tmp/corpusopssteroids/
RUN sh -c 'set -ex \
    && cd /tmp/corpusopssteroids \
    && chmod +x *sh \
    && ./apt_clean.sh \
    && cd / && rm -rf /tmp/corpusopssteroids'
