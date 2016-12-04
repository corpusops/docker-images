FROM library/python:3.5-alpine3.7
ARG DO_UPDATE=y
ARG NONINTERACTIVE=y
ARG INSTALL_DEFAULT_LOCALE="fr_FR.UTF-8"
ARG EXTRA_FILES_LIST=""
ARG COPS_SYSTEM=alpine
ARG FOREGO_RELEASE=latest
ARG GOSU_RELEASE=latest
ARG DOCKERIZE_RELEASE=latest
ARG CURL_SSL_OPTS=--tlsv1
ARG DOCKER_IMAGES_COMMIT=master
ADD \
    helpers/up.sh \
    helpers/add_gosu.sh \
    helpers/add_confd.sh \
    helpers/add_dockerize.sh \
    helpers/add_forego.sh \
    helpers/add_opt_pkgs.sh \
    helpers/setup_locales.sh \
    helpers/cops_pkgmgr_install.sh \
    helpers/alpine_up.sh \
    rootfs/ \
    packages/packages_alpine.txt \
    packages/optional_packages_supervisors.txt \
    packages/optional_packages_alpine.txt \
    ${EXTRA_FILES_LIST} \
    /tmp/corpusopssteroids/
RUN sh -c 'set -ex \
    && cd /tmp/corpusopssteroids \
    && chmod +x *sh \
    && cat optional_packages_*.txt > optional_packages.txt \
    && cat packages_*.txt > packages.txt \
    && : fix logrorate global conf \
    && if [ -e /var/log ];then touch /var/log/syslog /var/log/messages;fi \
    && ./alpine_up.sh \
    && ./add_opt_pkgs.sh \
    && ./add_confd.sh \
    && ./add_dockerize.sh \
    && ./add_gosu.sh \
    && ./add_forego.sh \
    && DEBUG=1 ./setup_locales.sh \
    && cp -v bin/* setup_locales.sh cops_pkgmgr_install.sh /bin \
    '
COPY --from=ochinchina/supervisord:latest \
    /usr/local/bin/supervisord /bin/supervisord-go
ADD helpers/alpine_clean.sh /tmp/corpusopssteroids/
RUN sh -c 'set -ex \
    && cd /tmp/corpusopssteroids \
    && chmod +x *sh \
    && ./alpine_clean.sh \
    && cd / && rm -rf /tmp/corpusopssteroids'
LABEL com.github.corpusops.docker-images-commit="$DOCKER_IMAGES_COMMIT"
