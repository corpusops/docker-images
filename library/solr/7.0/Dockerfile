FROM library/solr:7.0
ARG DO_UPDATE=y
ARG NONINTERACTIVE=y
ARG INSTALL_DEFAULT_LOCALE="fr_FR.UTF-8"
ARG EXTRA_PACKAGES_LIST="packages/packages_apt.txt"
ARG COPS_SYSTEM=apt
ARG FOREGO_RELEASE=latest
ARG GOSU_RELEASE=latest
ARG DOCKERIZE_RELEASE=latest
ARG CURL_SSL_OPTS=--tlsv1
USER root
ADD \
    helpers/up.sh \
    helpers/add_gosu.sh \
    helpers/add_dockerize.sh \
    helpers/add_forego.sh \
    helpers/add_opt_pkgs.sh \
    helpers/setup_locales.sh \
    helpers/cops_pkgmgr_install.sh \
    helpers/apt_up.sh \
    packages/packages_apt.txt \
    packages/optional_packages_supervisors.txt \
    packages/optional_packages_apt.txt \
    ${EXTRA_PACKAGES_LIST} \
    /tmp/corpusopssteroids/
RUN sh -c 'set -ex \
    && cd /tmp/corpusopssteroids \
    && chmod +x *sh \
    && cat optional_packages_*.txt > optional_packages.txt \
    && cat packages_*.txt > packages.txt \
    && ./apt_up.sh \
    && ./add_opt_pkgs.sh \
    && ./add_dockerize.sh \
    && ./add_gosu.sh \
    && ./add_forego.sh \
    && DEBUG=1 ./setup_locales.sh \
    && cp -v cops_pkgmgr_install.sh /bin \
    '
COPY --from=ochinchina/supervisord:latest \
    /usr/local/bin/supervisord /bin/supervisord-go
ADD helpers/apt_clean.sh /tmp/corpusopssteroids/
RUN sh -c 'set -ex \
    && cd /tmp/corpusopssteroids \
    && chmod +x *sh \
    && ./apt_clean.sh \
    && cd / && rm -rf /tmp/corpusopssteroids'
USER solr
