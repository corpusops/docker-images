FROM library/solr:6.6-alpine
ARG DO_UPDATE=y
ARG NONINTERACTIVE=y
ARG INSTALL_DEFAULT_LOCALE="fr_FR.UTF-8"
ARG EXTRA_FILES_LIST=""
ARG COPS_SYSTEM=${_cops_SYSTEM}
ARG FOREGO_RELEASE=latest
ARG REMCO_RELEASE=latest
ARG GOSU_RELEASE=latest
ARG DOCKERIZE_RELEASE=latest
ARG CURL_SSL_OPTS=--tlsv1
ARG DOCKER_IMAGES_COMMIT=master
USER root
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
    && DEBUG=1 ./setup_locales.sh \
    && sed -i -re "/var\\/log\\/messages \\{\\}/d" /etc/logrotate.conf\
    && sed -i -re "s/ dateext/nodateext/g" /etc/logrotate.conf\
    && if ! (grep -q /var/log/messages /etc/logrotate.conf);then\
           printf "\\n/var/log/messages {\\nmissingok\\n}\\n\\n" >>/etc/logrotate.conf;fi\
    && cp -v bin/* system_detect.sh setup_locales.sh \
        cops_pkgmgr_install.sh /bin \
    && ./${_cops_SYSTEM}_clean.sh \
    '
COPY --from=ochinchina/supervisord:latest \
    /usr/local/bin/supervisord /bin/supervisord-go
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
ADD helpers/*_clean.sh /tmp/corpusopssteroids/
RUN sh -c 'set -ex \
    && cd /tmp/corpusopssteroids \
    && chmod +x *sh \
    && _cops_SYSTEM=$(./system_detect.sh) \
    && ./${_cops_SYSTEM}_clean.sh \
    && cd / && rm -rf /tmp/corpusopssteroids'
USER solr
LABEL com.github.corpusops.docker-images-commit="$DOCKER_IMAGES_COMMIT"
