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

## Wrapped images

- [![Build Status](https://travis-ci.org/corpusops/docker-images.svg?branch=master)](https://travis-ci.org/corpusops/docker-images)

| original  | corpusops  |
|------------|-----------|
| [library/alpine](https://hub.docker.com/_/alpine)([./library/alpine](./library/alpine))                                       | [corpusops/alpine-bare](https://hub.docker.com/r/corpusops/alpine-bare)         |
| [library/centos](https://hub.docker.com/_/centos)([./library/centos](./library/centos))                                       | [corpusops/centos-bare](https://hub.docker.com/r/corpusops/centos-bare)         |
| [library/debian](https://hub.docker.com/_/debian)([./library/debian](./library/debian))                                       | [corpusops/debian-bare](https://hub.docker.com/r/corpusops/debian-bare)         |
| [library/elasticsearch](https://hub.docker.com/_/elasticsearch)([./library/elasticsearch](./library/elasticsearch))           | [corpusops/elasticsearch](https://hub.docker.com/r/corpusops/elasticsearch)     |
| [library/fedora](https://hub.docker.com/_/fedora)([./library/fedora](./library/fedora))                                       | [corpusops/fedora-bare](https://hub.docker.com/r/corpusops/fedora-bare)         |
| [library/golang](https://hub.docker.com/_/golang)([./library/golang](./library/golang))                                       | [corpusops/golang](https://hub.docker.com/r/corpusops/golang)                   |
| [library/mongo](https://hub.docker.com/_/mongo)([./library/mongo](./library/mongo))                                           | [corpusops/mongo](https://hub.docker.com/r/corpusops/mongo)                     |
| [library/mysql](https://hub.docker.com/_/mysql)([./library/mysql](./library/mysql))                                           | [corpusops/mysql](https://hub.docker.com/r/corpusops/mysql)                     |
| [library/nginx](https://hub.docker.com/_/nginx)([./library/nginx](./library/nginx)) ( also add **htpasswd** )                 | [corpusops/nginx](https://hub.docker.com/r/corpusops/nginx)                     |
| [library/traefik](https://hub.docker.com/_/traefik)([./library/traefik](./library/traefik))                                   | [corpusops/traefik](https://hub.docker.com/r/corpusops/traefik)                 |
| [library/php](https://hub.docker.com/_/php)([./library/php](./library/php))                                                   | [corpusops/php](https://hub.docker.com/r/corpusops/php)                         |
| [library/postgres](https://hub.docker.com/_/postgres)([./library/postgres](./library/postgres))                               | [corpusops/postgres](https://hub.docker.com/r/corpusops/postgres)               |
| [library/python](https://hub.docker.com/_/python)([./library/python](./library/python))                                       | [corpusops/python](https://hub.docker.com/r/corpusops/python)                   |
| [library/ruby](https://hub.docker.com/_/ruby)([./library/ruby](./library/ruby))                                               | [corpusops/ruby](https://hub.docker.com/r/corpusops/ruby)                       |
| [library/solr](https://hub.docker.com/_/solr)([./library/solr](./library/solr))                                               | [corpusops/solr](https://hub.docker.com/r/corpusops/solr)                       |
| [library/wordpress](https://hub.docker.com/_/wordpress)([./library/wordpress](./library/wordpress))                           | [corpusops/wordpress](https://hub.docker.com/r/corpusops/wordpress)             |
| [library/redis](https://hub.docker.com/_/redis)([./library/redis](./library/redis))                                           | [corpusops/redis](https://hub.docker.com/r/corpusops/redis)                     |
| [library/rabbitmq](https://hub.docker.com/_/rabbitmq)([./library/rabbitmq](./library/rabbitmq))                                           | [corpusops/rabbitmq](https://hub.docker.com/r/corpusops/rabbitmq)   |
| [library/opensuse](https://hub.docker.com/_/opensuse)([./library/opensuse](./library/opensuse))                               | [corpusops/opensuse-bare](https://hub.docker.com/r/corpusops/opensuse-bare)     |
| [library/ubuntu](https://hub.docker.com/_/ubuntu)([./library/ubuntu](./library/ubuntu))                                       | [corpusops/ubuntu-bare](https://hub.docker.com/r/corpusops/ubuntu-bare)         |
| [makinacorpus/pgrouting](https://hub.docker.com/r/makinacorpus/pgrouting)([./makinacorpus/pgrouting](./makinacorpus/pgrouting)) | [corpusops/pgrouting](https://hub.docker.com/r/corpusops/pgrouting)             |
| [mdillon/postgis](https://hub.docker.com/r/mdillon/postgis)([./mdillon/postgis](./mdillon/postgis))                             | [corpusops/postgis](https://hub.docker.com/r/corpusops/postgis)                 |
| [mailhog/mailhog](https://hub.docker.com/r/mailhog/mailhog)([./mailhog/mailhog](./mailhog/mailhog))                             | [corpusops/mailhog](https://hub.docker.com/r/corpusops/mailhog)                 |
| [minio/k8s-operator](https://hub.docker.com/r/minio/k8s-operator)([./minio/k8s-operator](./minio/k8s-operator))                 | [corpusops/minio-k8s-operator](https://hub.docker.com/r/corpusops/minio-k8s-operator)       |
| [minio/doctor](https://hub.docker.com/r/minio/doctor)([./minio/doctor](./minio/doctor))                                         | [corpusops/minio-doctor](https://hub.docker.com/r/corpusops/minio-doctor)                   |
| [minio/mint](https://hub.docker.com/r/minio/mint)([./minio/mint](./minio/mint))                                                 | [corpusops/minio-mint](https://hub.docker.com/r/corpusops/minio-mint)                       |
| [minio/minio](https://hub.docker.com/r/minio/minio)([./minio/minio](./minio/minio))                                             | [corpusops/minio](https://hub.docker.com/r/corpusops/minio)                     |
| [minio/mc](https://hub.docker.com/r/minio/mc)([./minio/mc](./minio/mc))                                                         | [corpusops/mc](https://hub.docker.com/r/corpusops/mc)                           |
| [mailu/postfix](https://hub.docker.com/r/mailu/postfix)([./mailu/postfix](./mailu/postfix))                                     | [corpusops/mailu-postfix](https://hub.docker.com/r/corpusops/mailu-postfix)     |
| [mailu/rspamd](https://hub.docker.com/r/mailu/rspamd)([./mailu/rspamd](./mailu/rspamd))                                     | [corpusops/mailu-rspamd](https://hub.docker.com/r/corpusops/mailu-rspamd)     |
| [appbaseio/dejavu](https://hub.docker.com/r/appbaseio/dejavu)([./appbaseio/dejavu](./appbaseio/dejavu))                         | [corpusops/dejavu](https://hub.docker.com/r/corpusops/dejavu)                   |

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
    - ``SUPERVISORD_CONFIGS`` can be set to alternate configs to aggregate to supervisord config
    - ``SUPERVISORD_LOGFILE`` can be set up to another path, as we set it to stdout by defaut
- One usual way to use this providen entrypoint is to launch it through supervisor to gain also logrotate support for free.<br/>

    ```yaml
    supervisord:
      image: "corpusops/supervisord"
      entrypoint: /bin/supervisord.sh
      environment:
      - export SUPERVISORD_LOGFILE=/dev/stdout
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
- One usual way to use this providen entrypoint is to launch it through forego to gain also logrotate support for free.<br/>
  Remember also that all files in ``/etc/nginx`` will be proccessed by frep
  and all variables prefixed by ``NGINX_`` will be replaced. Also .template files
  will be skipped (eg: /etc/nginx/foo.template). We integrated both supervisord (recommended) and forego configs
    - supervisord example

        ```yaml
        nginx:
          command: >
            /bin/sh -c "
            frep /etc/nginx/conf.d/default.conf.template:/etc/nginx/conf.d/default.conf --overwrite
            && exec /bin/supervisord.sh"
          environment:
          - SUPERVISORD_CONFIGS=/etc/supervisor.d/cron /etc/supervisor.d/nginx
          volumes:
          - ./myvhost.conf:/etc/nginx/conf.d/default.conf.template

        ```

    - forego example

        ```yaml
        nginx:
          command: >
            /bin/sh -c "
            CONF_PREFIX=MYAPP__ confenvsubst.sh /etc/nginx/conf.d/default.conf.template
            > /etc/nginx/conf.d/default.conf
            && : exec /bin/forego.sh"
          environment:
          - FOREGO_PROCFILE=/etc/procfiles/nginx_logrotate.Procfile
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

## Support development
- [paypal](https://paypal.me/kiorky)

