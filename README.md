# library images on steroids

## doc
- Idea is to inject some tools inside base library images
- We do not wrap ``ONBUILD`` based images.
- For all we want:
    -  the network swissknifes:
        [socat](http://www.dest-unreach.org/socat/),
        [netcat](http://netcat.sourceforge.net/),
        [curl](https://curl.haxx.se/),
        [wget](https://www.gnu.org/software/wget/).
    - [cops_pkgmgr_install.sh](https://github.com/corpusops/corpusops.bootstrap/blob/master/bin/cops_pkgmgr_install.sh): arch agnostic package installer
    - [setup_locales.sh](./helpers/setup_locales.sh): helper to build and setup the default locale
    - [openssl](https://www.openssl.org/): The SSL toolkit.
    - [cron](https://fr.wikipedia.org/wiki/Cron): isc cron on debian like, cronie on redhat, busybox cron on alpine (dcron).
    - [rsyslog](https://www.rsyslog.com/): the system logger
    - [logrotate](https://github.com/logrotate/logrotate): the venerable but still useful versatile logrotator
    - [bash](https://www.gnu.org/software/bash/): the venerable shell
    - ca certificates: bundle of ROOT cas for SSL connections.
    - process supervisors:
        - [forego](https://github.com/ddollar/forego): *foreman in go*, supervisord/runit/circus/foreman alike
        - [supervisord-go](https://github.com/ochinchina/supervisord): *supervisord in go*, attention, it has bugs like PID1 proccess reaping issues, use with care and read [the tracker](https://github.com/ochinchina/supervisord/issues) and specially [#60](https://github.com/ochinchina/supervisord/issues/60)!
        - [runit](http://smarden.org/runit/) (1)
        - [monit](https://mmonit.com/monit/) (1)
        - foreman(ruby) & supervisord (python) are not bundled
          as they would add too much dependencies
          therefore make images grow too much.
    - [frep](https://github.com/subchen/frep): tool to generates configs from templates when envsubst or basic shell is just not enougth
    - [confd](https://github.com/kelseyhightower/confd): tool to generates configs from templates when frep is just not enougth
    - [remco](https://github.com/HeavyHorst/remco): tool to generates configs from templates when confd is just not enougth
    - [dockerize](https://github.com/jwilder/dockerize): tool to orchestrate containers between themselves
    - [gosu](https://github.com/tianon/gosu): tool to downgrade privileges, the perfect SUDO.
    - [confenvsubst](./rootfs/bin/confenvsubst.sh): tool to generate configs from env vars with well knows prefixes
    - [p7zip](http://p7zip.sourceforge.net/): the universal (un)archiver
    - Except for alpine based images (using musl, so no locales): setup sensible locales for: ``fr``, ``en``, ``de``.

- (1): if it is packaged on the underlying distrib (eg: runit is only on alpine>3)
- debian 6 (stretch) is not supported anymore.
- To be sure to include new tags nearly as soon as they are out, and to also refresh images to include
  their fixes including security patches, this repo has a Travis cron enabled to rebuild everything at least daily.
- Note: All single binaries and scripts are installed inside `/cops_helpers`, you can them use any docker-images related image as a source to ignite a volume or use multistage builds to copy them.

## Separatly mananged images
- `corpusops/postgres`, `corpusops/pgrouting` & `corpusops/postgis` pipelines has been moved to [this repo](https://github.com/corpusops/docker-postgresql)
   and those 2 children: [postgis](https://github.com/corpusops/docker-postgis) / [pgrouting](https://github.com/corpusops/docker-pgrouting)

| repo  | status  |
|------------|-----------|
| [docker-images](https://github.com/corpusops/docker-images)    | [![images](https://github.com/corpusops/docker-images/workflows/.github/workflows/cicd.yml/badge.svg?branch=master)](https://github.com/corpusops/docker-images/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amaster) |
| [docker-postgis](https://github.com/corpusops/docker-postgis)   | [![postgis](https://github.com/corpusops/docker-postgis/workflows/.github/workflows/cicd.yml/badge.svg?branch=master)](https://github.com/corpusops/docker-postgis/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amaster) |
| [docker-pgrouting](https://github.com/corpusops/docker-pgrouting) | [![pgrouting](https://github.com/corpusops/docker-pgrouting/workflows/.github/workflows/cicd.yml/badge.svg?branch=master)](https://github.com/corpusops/docker-pgrouting/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amaster) |
| [docker-postgres](https://github.com/corpusops/docker-postgresql)  | [![postgres](https://github.com/corpusops/docker-postgresql/workflows/.github/workflows/cicd.yml/badge.svg?branch=master)](https://github.com/corpusops/docker-postgresql/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amaster)  |

- other images managed separatly

| repo  | status  |
|------------|-----------|
| [docker-archlinux](https://github.com/corpusops/docker-archlinux)  | [![archlinux](https://github.com/corpusops/docker-archlinux/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-archlinux/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-alpine](https://github.com/corpusops/docker-alpine)  | [![alpine](https://github.com/corpusops/docker-alpine/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-alpine/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-debian](https://github.com/corpusops/docker-debian)  | [![debian](https://github.com/corpusops/docker-debian/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-debian/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-fedora](https://github.com/corpusops/docker-fedora)  | [![fedora](https://github.com/corpusops/docker-fedora/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-fedora/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-centos](https://github.com/corpusops/docker-centos)  | [![centos](https://github.com/corpusops/docker-centos/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-centos/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-amazonlinux](https://github.com/corpusops/docker-amazonlinux)  | [![amazonlinux](https://github.com/corpusops/docker-amazonlinux/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-amazonlinux/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-amazonlinux](https://github.com/corpusops/docker-amazonlinux-bare)  | [![amazonlinux](https://github.com/corpusops/docker-amazonlinux-bare/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-amazonlinux-bare/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-ubuntu](https://github.com/corpusops/docker-ubuntu)  | [![ubuntu](https://github.com/corpusops/docker-ubuntu/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-ubuntu/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-vault](https://github.com/corpusops/docker-vault)  | [![vault](https://github.com/corpusops/docker-vault/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-vault/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-php](https://github.com/corpusops/docker-php)  | [![php](https://github.com/corpusops/docker-php/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-php/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-ruby](https://github.com/corpusops/docker-ruby)  | [![ruby](https://github.com/corpusops/docker-ruby/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-ruby/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-nginx](https://github.com/corpusops/docker-nginx)  | [![nginx](https://github.com/corpusops/docker-nginx/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-nginx/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-node](https://github.com/corpusops/docker-node)  | [![node](https://github.com/corpusops/docker-node/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-node/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-python](https://github.com/corpusops/docker-python)  | [![python](https://github.com/corpusops/docker-python/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-python/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-golang](https://github.com/corpusops/docker-golang)  | [![golang](https://github.com/corpusops/docker-golang/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-golang/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-traefik](https://github.com/corpusops/docker-traefik)  | [![traefik](https://github.com/corpusops/docker-traefik/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-traefik/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-docker](https://github.com/corpusops/docker-docker)  | [![docker](https://github.com/corpusops/docker-docker/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-docker/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-mongo](https://github.com/corpusops/docker-mongo)  | [![mongo](https://github.com/corpusops/docker-mongo/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-mongo/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-mysql](https://github.com/corpusops/docker-mysql)  | [![mysql](https://github.com/corpusops/docker-mysql/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-mysql/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-mariadb](https://github.com/corpusops/docker-mariadb)  | [![mariadb](https://github.com/corpusops/docker-mariadb/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-mariadb/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-redis](https://github.com/corpusops/docker-redis)  | [![redis](https://github.com/corpusops/docker-redis/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-redis/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-redmine](https://github.com/corpusops/docker-redmine)  | [![redmine](https://github.com/corpusops/docker-redmine/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-redmine/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-solr](https://github.com/corpusops/docker-solr)  | [![solr](https://github.com/corpusops/docker-solr/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-solr/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-rabbitmq](https://github.com/corpusops/docker-rabbitmq)  | [![rabbitmq](https://github.com/corpusops/docker-rabbitmq/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-rabbitmq/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-elasticsearch](https://github.com/corpusops/docker-elasticsearch)  | [![elasticsearch](https://github.com/corpusops/docker-elasticsearch/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-elasticsearch/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-opensearch](https://github.com/corpusops/docker-opensearch)  | [![opensearch](https://github.com/corpusops/docker-opensearch/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-opensearch/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-opensuse](https://github.com/corpusops/docker-opensuse)  | [![opensuse](https://github.com/corpusops/docker-opensuse/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-opensuse/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-minio](https://github.com/corpusops/docker-minio)  | [![minio](https://github.com/corpusops/docker-minio/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-minio/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-mailu](https://github.com/corpusops/docker-mailu)  | [![mailu](https://github.com/corpusops/docker-mailu/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-mailu/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-wordpress](https://github.com/corpusops/docker-wordpress)  | [![wordpress](https://github.com/corpusops/docker-wordpress/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-wordpress/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-tensorflow](https://github.com/corpusops/docker-tensorflow)  | [![tensorflow](https://github.com/corpusops/docker-tensorflow/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-tensorflow/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-memcached](https://github.com/corpusops/docker-memcached)  | [![memcached](https://github.com/corpusops/docker-memcached/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-memcached/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-seafile](https://github.com/corpusops/docker-seafile)  | [![seafile](https://github.com/corpusops/docker-seafile/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-seafile/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-mailhog](https://github.com/corpusops/docker-mailhog)  | [![mailhog](https://github.com/corpusops/docker-mailhog/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-mailhog/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-slapd](https://github.com/corpusops/docker-slapd)  | [![slapd](https://github.com/corpusops/docker-slapd/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-slapd/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-sshd](https://github.com/corpusops/docker-sshd)  | [![sshd](https://github.com/corpusops/docker-sshd/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-sshd/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-gitlabtools](https://github.com/corpusops/docker-gitlabtools)  | [![gitlabtools](https://github.com/corpusops/docker-gitlabtools/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-gitlabtools/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |
| [docker-project](https://github.com/corpusops/docker-project)  | [![project](https://github.com/corpusops/docker-project/workflows/.github/workflows/cicd.yml/badge.svg?branch=main)](https://github.com/corpusops/docker-project/actions?query=workflow%3A.github%2Fworkflows%2Fcicd.yml+branch%3Amain)  |


- Those helpers (docker entrypoints) are added:


## Refresh some files in this repository
- Think time to time to refresh ``cops_pkgmgr_install.sh`` comes from [corpusops.bootstrap/bin](https://github.com/corpusops/corpusops.bootstrap/blob/master/bin/cops_pkgmgr_install.sh)
- Then run

    ```sh
    ./main.sh gen
    ```
- Commit the whole and check build status on [travis](https://travis-ci.org/corpusops/docker-images/builds)
- Image can override any of the hooks in this order (placing a ``Dockerfile.<hook_name>`` in the image folder (precedence: tag folder itself, imagefolder (for all tags), and the default ones)
    - [from](./Dockerfile.from)
    - [args](./Dockerfile.args)
    - ``argspost``: just a hook (empty by default)
    - [helpers](./Dockerfile.helpers)
    - ``pre``: just a hook (empty by default)
    - [base](./Dockerfile.base)
    - ``post``: just a hook (empty by default)
    - [clean](./Dockerfile.clean)
    - ``cleanpost``: just a hook (empty by default)

## Zoom on entryoints
You better have to read the entrypoints to understand how they work.

### supervisord helper: /bin/supervisord.sh
- [/bin/supervisord.sh](./rootfs/bin/supervisord.sh): helper to dockerize supervisord-go
    - generates its config (read the helper) by concatenating all config (.conf, .ini) files
      found inside subdirectories of <br/>
      ``/etc/supervisor.d``, ``/etc/supervisor``, ``/etc/supervisord``, in t
    - frep is done on config files for all vars beginning by ``SUPERVISORD_``
    - ``SUPERVISORD_CONFIGS`` can be set to alternate configs to aggregate to supervisord config, if the file is with a relative path, it will be searched inside /etc/supervisord.d
    - ``SUPERVISORD_LOGFILE`` can be set up to another path, as we set it to stdout by defaut
- One usual way to use this providen entrypoint is to launch it through supervisor to gain also logrotate support for free.<br/>

    ```yaml
    # configs can be given on CLI, v2
    supervisord:
      image: "corpusops/supervisord"
      command:  /bin/supervisord.sh s.conf
    # configs can be given on CLI, v1
    supervisord:
      image: "corpusops/supervisord"
      entrypoint: /bin/supervisord.sh
      command: [s.conf]
    # /etc/supervisor.d/s.conf is a valid supervisord config snipped
    supervisord:
      image: "corpusops/supervisord"
      entrypoint: /bin/supervisord.sh
      environment:
      - SUPERVISORD_CONFIGS=s.conf
    # /foo/s.conf is a valid supervisord config snipped
    supervisord:
      image: "corpusops/supervisord"
      entrypoint: /bin/supervisord.sh
      environment:
      - SUPERVISORD_CONFIGS=/foo/s.conf
    ```

### forego helper: /bin/forego.sh
- [/bin/forego.sh](./rootfs/bin/forego.sh): helper to dockerize forego :
    - envsubst is done on Procfiles for all vars beginning by ``FOREGO_``
- As you may know, forego uses a Procfile to configure itself.
    - You can either use this entrypoint directly by giving args including the Procfile
    - Or, easier, you can use The ``PROCFILE`` env var pointing to your config.

      - This config file will be parsed by envsubst.

    ```yaml
    nginx:
      command: "corpusops/nginx"
      entrypoint: /bin/forego.sh -d /my/path
      environment:
      # This way your procfile can be processed by envsubst !
      - FOREGO_PROCFILE=/my/path/.Procfile
    ```

### cron helper: /bin/cron.sh
- [/bin/cron.sh](./rootfs/bin/cron.sh): helper to dockerize cron
- When you use a debian/ubuntu based image, it's impossible to use cron base logging as it is based on syslog.<br>
    - see [this bug](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=887035)
- When you use other implementation, you can redirect to a file, but it won't end up into docker logs.
- So we made an entrypoint
    - 1. to handle different implementation startup arguments
    - 2. to handle a named pipe to escalate cron logs up to docker logs instead of a regular log file.
- What you have to do to log is to redirect output to ``/var/log/cron.log``.
    - Usage is as easy as putting this in your docker-compose file

        ```yaml
        ```
    - ALT: (not recommanded) without supervisor:

        ```yaml
        ---
        version: "3.6"
        services:
          # for alpine
          alpinecron:
            image: corpusops/alpine-bare
            command:
            - /bin/sh
            - "-c"
            - >-
              frep /mycrontab.frep:/etc/crontabs/mycrontab --overwrite
              && chmod 0700 /etc/crontabs/mycrontab
              && exec /bin/supervisord.sh
            environment:
            - SUPERVISORD_CONFIGS=/etc/supervisor.d/cron /etc/supervisor.d/rsyslog
            volumes:
            - ./mycrontab:/mycrontab.frep
            - ../rootfs/etc/rsyslog.conf.frep:/etc/rsyslog.conf.frep
          # for debian/redhat alike
          ubuntucron:
            image: corpusops/ubuntu-bare
            command:
            - /bin/sh
            - "-c"
            - >-
              frep /mycrontab.frep:/etc/cron.d/mycrontab --overwrite
              && chmod 0700 /etc/cron.d/mycrontab
              && exec /bin/supervisord.sh
            environment:
            - SUPERVISORD_CONFIGS=/etc/supervisor.d/cron /etc/supervisor.d/rsyslog
            volumes:
            - ./umycrontab:/mycrontab.frep
            - ../rootfs/etc/rsyslog.conf.frep:/etc/rsyslog.conf.frep
        ```
    - mycrontab

        ```cron
        # debian / ubuntu / centos: /etc/crond.d/mycrontab
        1 * * * * * root gosu myuser /bin/sh -c "backup 2>&1 | tee -a /var/log/cron.log"
        # alpine: /etc/crontabs/mycrontab
        1 * * * * * gosu myuser /bin/sh -c "backup 2>&1 | tee -a /var/log/cron.log"
        ```

### nginx helper: /bin/nginx.sh
- [/bin/nginx.sh](./rootfs/bin/nginx.sh): helper to dockerize nginx
- One usual way to use this providen entrypoint is to launch it through supervisord-go to gain also logrotate support for free.
- Remember also that all files in ``/etc/nginx`` will be proccessed by frep<br/>
- Remember also that all files in ``/nginx.d`` if existing will be proccessed by frep with same rules and copied to /etc/nginx<br/>
- Also ".skip|.template" files will be skipped from processing (eg: /etc/nginx/foo.template) but you can adapt the `NGINX_FREP_SKIP` envvar to any regex to skip other files from frep processing
- if `NO_SSL` is not set, generate a self signed certificate if the certificate provided path is not already existing.
- Useful vars:
    - `NGINX_FREP_SKIP=.skip|.template|.skipped`: skip rendering files matching regex
    - `SKIP_EXTRA_CONF=`: set to 1 to skip extra conf in /nginx.d copy
    - `SKIP_CONF_RENDER=`: set to 1 skip frep rendering
    - `SKIP_OPENSSL_INSTALL=`: set to 1 skip openssl autoinstall if not installed
    - `NGINX_HTTP_PROTECT_USER/NGINX_HTTP_PROTECT_PASSWORD`: generate `/etc/htpasswd-protect` htpasswd file  with those credentials
    - `NO_SSL=1`: set to 1 not to generate a selfisgned certificate for `SSL_CERT_BASENAME` and `SSL_ALT_NAMES` (space sparated)
    - `SSL_CERT_PATH=/certs/cert.pem`: ssl certificate path (also used when using the selfsigned certificate generator)
    - `SSL_KEY_PATH=/certs/cert.key`: ssl certificate key path
- examples
    - supervisord example

        ```yaml
        nginx:
          image: corpusops/nginx:1-alpine
          command: /bin/supervisord.sh
          environment: [SUPERVISORD_CONFIGS=cron nginx rsyslog]
          volumes:
          - ./nginx:/nginx.d

        ```

    - supervisord custom example

        ```yaml
        nginx:
          image: corpusops/nginx:1-alpine
          command: >
            /bin/sh -exc "
            frep /etc/nginx/conf.d/default.conf.template:/etc/nginx/conf.d/default.conf --overwrite
            && exec /bin/supervisord.sh"
          environment: [SUPERVISORD_CONFIGS=cron nginx rsyslog]
          volumes:
          - ./myvhost.conf:/etc/nginx/conf.d/default.conf.template

        ```

### SSL Certificate Helper: /bin/cops_gen_cert.sh
- see [script](./rootfs/bin/cops_gen_cert.sh)
- controlled via env vars:

    ```sh
    SSL_COMMON_NAME=  # default: $hostname
    SSL_ALT_NAMES=  # default: $hostname www.$hostname
    SSL_CERT_BASENAME=  # default to hostname and "cert" through nginx script
    SSL_CERT_PATH=
    SSL_KEY_PATH=
	SSL_KEY_VALIDITY=  # cert validity in days
	SSL_CERT_VALIDITY=  # cert validity in days
	SSL_DIR_MODuE=  # directory perms mode
	SSL_CERT_MODE=  # cert perms mode
	SSL_KEY_MODE=  # key perms mode
    SSL_CERT=  # x509 cert value if you want to give it
    SSL_KEY=   # x509 cert key value if you want to give it
    ```

- If ``SSL_CERT`` is empty, a SSL key will be generated
- If ``SSL_KEY`` is empty, a selfsigned cert will be generated

### traefik helper: /bin/traefik.sh
- [/bin/traefik.sh](./rootfs/bin/traefik.sh): helper to dockerize traefik
- As you may know, forego uses a Procfile to configure itself.
    - You can either use this entrypoint directly by giving args including the traefik config
    - Or, easier, you can use either
        - the ``TRAEFIK_CONFIG`` env var pointing to your config.
        - mount a file to ``/traefik.toml``
    - This config file will be parsed by envsubst for any env var prefixed by ``TRAEFIK_``.

        ```yaml
        traefik:
          image: "corpusops/traefik"
          entrypoint: /bin/traefik.sh
          environment:
          # if this file exists, it will be used as the config automatically
          - TRAEFIK_CONFIG=/traefik.toml
        ```


### Use rsyslog image
- See [./corpusops/rsyslog](./corpusops/rsyslog).
- tag is ``corpusops/rsyslog``
    - OS based variants:
        - ``corpusops/rsyslog:debian``
        - ``corpusops/rsyslog:alpine``
        - ``corpusops/rsyslog:ubuntu``
- this image exposes a syslog daemon on port ``10514``
- It will split with its default config every log inside ``/var/log/docker/<prog_name>.log``
- logs also go to stdout
- env vars (mainly to control log retention) [[see logrotate](./rootfs/etc/logrotate.d/rsyslog)]:
    - ``RSYSLOG_PORT=10514``: rsyslog port
    - ``LOGROTATE_SIZE=5M``: size to trigger a logrotate from.
    - ``LOGROTATE_DAYS=30``: number of days to keep logs for.
    - ``LOGROTATE_LONGRETENTION_DAYS=365``: number of days to keep long retention (web & loadbalancers) logs for.
    - ``RSYSLOG_DOCKER_LOGS_PATH=/var/log/docker``: path to logs
    - ``RSYSLOG_DOCKER_LONGRETENTION_LOGS_PATH=/var/log/docker/longretention``: path to logs with long retention
    - ``RSYSLOG_DOCKER_LONGRETENTION_PATTERN=^(lb|nginx|proxy|traefik|haproxy|apache)``: regex to know which tagnames can be treated as long retention logs
    - ``RSYSLOG_SPLITTED_CONFIGS=1``:
        - if ``1``: logs are splitted under ``/var/log/docker/<prog_name>.log``
        - else things go inside like usually in ``/var/log``
- Any file inside ``/entry`` will be copied to ``/etc`` with same location
- Any file named ``*.frep`` into ``/etc/logrotate.d`` && ``/etc/rsyslog.d`` will be processed through frep

One current pattern is to redirect docker logs through a local syslog this way:

```yaml
x-vars:
  base: &base
    restart: always
    # this will configure the baremetal host to reroute logs
    # through localhost:1514 which forwards to ``log`` container itself
    logging:
      driver: "syslog"
      options:
        syslog-address: "tcp://localhost:1514"
        tag: "someservice"
services:
  log:
    <<: [ *base ]
    image: corpuspops/rsyslog
    ports: ["127.0.0.1:1514:10514"]
    # ensure no syslog log loop
    logging: {driver: "json-file", options: {max-size: "10M", max-file: "50"}}
  someservice:
    <<: [ *base ]
    image: some/service
```

