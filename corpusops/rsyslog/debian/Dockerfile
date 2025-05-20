ARG ANCESTOR=corpusops/rsyslog:debian
ARG RSYNC=corpusops/rsync
FROM corpusops/ubuntu-bare:latest AS final
ARG DO_UPDATE=y
ARG NONINTERACTIVE=y
ARG DEBIAN_FRONTEND=noninteractive
ARG INSTALL_DEFAULT_LOCALE="fr_FR.UTF-8"
ARG EXTRA_FILES_LIST=""
ARG COPS_SYSTEM=${_cops_SYSTEM}
ARG FOREGO_RELEASE=latest
ARG REMCO_RELEASE=latest
ARG GOSU_RELEASE=latest
ARG DOCKERIZE_RELEASE=latest
ARG CURL_SSL_OPTS=--tlsv1
ARG DOCKER_IMAGES_COMMIT=master
ARG COPS_HELPERS=/cops_helpers
ADD \
    helpers/up.sh \
    helpers/add_gosu.sh \
    helpers/system_detect.sh \
    helpers/add_frep.sh \
    helpers/add_confd.sh \
    helpers/add_dockerize.sh \
    helpers/add_forego.sh \
    helpers/add_opt_pkgs.sh \
    helpers/add_remco.sh \
    helpers/setup_locales.sh \
    helpers/cops_pkgmgr_install.sh \
    helpers/*_up.sh \
    helpers/*_clean.sh \
    rootfs/ \
    packages/*packages*.txt \
    ${EXTRA_FILES_LIST} \
    /tmp/corpusopssteroids/
RUN sh -c 'set -ex \
    && cd /tmp/corpusopssteroids \
    && : \
    && chmod +x *sh \
    && if [ ! -e $COPS_HELPERS ];then mkdir -p "$COPS_HELPERS";fi \
    && export PATH=$(pwd):$PATH \
    && _cops_SYSTEM=$(./system_detect.sh) \
    && cat ${_cops_SYSTEM}_optional_packages*.txt optional_packages*.txt > optional_packages.txt \
    && cat ${_cops_SYSTEM}_packages*.txt > packages.txt \
    && : fix logrorate global conf \
    && if [ -e /var/log ];then touch /var/log/syslog /var/log/messages;fi \
    && ./${_cops_SYSTEM}_up.sh \
    && ./add_opt_pkgs.sh \
    && ./add_frep.sh \
    && ./add_remco.sh \
    && ./add_confd.sh \
    && ./add_dockerize.sh \
    && ./add_gosu.sh \
    && ./add_forego.sh \
    && ln -sfv ${COPS_HELPERS}/supervisord-go /bin/supervisord-go \
    && DEBUG=1 ./setup_locales.sh \
    && sed -i -re "/var\\/log\\/messages \\{\\}/d" /etc/logrotate.conf\
    && sed -i -re "s/ dateext/nodateext/g" /etc/logrotate.conf\
    && if ! (grep -q /var/log/messages /etc/logrotate.conf);then\
           printf "\\n/var/log/messages {\\nmissingok\\n}\\n\\n" >>/etc/logrotate.conf;fi\
    && for i in bin/* system_detect.sh setup_locales.sh cops_pkgmgr_install.sh;do j=$(basename $i);cp -v $i /cops_helpers && ln -sfv /cops_helpers/$j /bin/$j;done\
    && ./${_cops_SYSTEM}_clean.sh \
    '
COPY --from=ochinchina/supervisord:latest \
    /usr/local/bin/supervisord ${COPS_HELPERS}/supervisord-go
ADD \
    rootfs/etc/rsyslog.d/ \
    /etc/rsyslog.d/
ADD \
    rootfs/etc/rsyslog.conf.frep \
    /etc/rsyslog.conf.frep
ADD \
    rootfs/etc/supervisor.d/rsyslog \
    rootfs/etc/supervisor.d/cron \
    /etc/supervisor.d/
ADD rootfs/etc/logrotate.conf /etc/
ADD rootfs/etc/logrotate.d/* /etc/logrotate.d/
ADD helpers/system_detect.sh helpers/*_clean.sh /tmp/corpusopssteroids/
RUN sh -c 'set -ex \
    && echo fixperms >&2 \
    && ( chmod -vf g-wx,o-wx /etc/logrotate.d/* /etc/logrotate.conf || true ) \
    && echo cleanup >&2 \
    && cd /tmp/corpusopssteroids \
    && chmod +x *sh \
    && _cops_SYSTEM=$(./system_detect.sh) \
    && ./${_cops_SYSTEM}_clean.sh \
    && ./common_clean.sh \
    && cd / && rm -rf /tmp/corpusopssteroids /var/cache/apk/* /var/lib/apt/lists/*'
FROM $RSYNC AS squashed-rsync
FROM $ANCESTOR AS squashed-ancestor
ARG ROOTFS="/BASE_ROOTFS_TO_COPY_THAT_WONT_COLLIDE_1234567890"
ARG PATH="${ROOTFS}_rsync/bin:$PATH"
SHELL ["busybox",  "sh", "-c"]
RUN --mount=type=bind,from=final,target=$ROOTFS --mount=type=bind,from=squashed-rsync,target=${ROOTFS}_rsync \
rsync -Aaz --delete ${ROOTFS}/ / --exclude=/proc --exclude=/sys --exclude=/etc/resolv.conf --exclude=/etc/hosts --exclude=$ROOTFS* --exclude=dev/shm --exclude=dev/pts --exclude=dev/mqueue
SHELL ["/bin/sh", "-c"]
ARG DEV_DEPENDENCIES_PATTERN='^#\s*dev dependencies'
ADD /images/rsyslog/ /install
RUN \
  set -e \
  && cd install \
  && sed -i -re "s/(python-?)[0-9]\.[0-9]+/\1$PY_VER/g" pkgs.txt \
  && cops_pkgmgr_install.sh $(grep -E -v '^#' pkgs.txt) \
  && rm -rf /var/cache/apk/* /var/lib/apt/lists/*
USER root
ENV SUPERVISORD_CONFIGS="cron rsyslog"\
    SYSLOG_ONLY="1"\
    RSYSLOG_SPLITTED_CONFIGS="1"
ENTRYPOINT ["/bin/supervisord.sh"]
ARG DOCKER_IMAGES_COMMIT="$DOCKER_IMAGES_COMMIT"
LABEL com.github.corpusops.docker-images-commit="$DOCKER_IMAGES_COMMIT"
