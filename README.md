# library images on steroids

## doc
- Idea is to inject some tools inside base library images
- For all we want:
    -  the network swissknifes:
        [socat](http://www.dest-unreach.org/socat/),
        [netcat](http://netcat.sourceforge.net/),
        [curl](https://curl.haxx.se/),
        [wget](https://www.gnu.org/software/wget/).
    - [cops_pkgmgr_install.sh](https://github.com/corpusops/corpusops.bootstrap/blob/master/bin/cops_pkgmgr_install.sh): arch agnostic package installer
    - [cron](https://fr.wikipedia.org/wiki/Cron): isc cron on debian like, cronie on redhat, busybox cron on alpine (dcron).
    - [logrotate](https://github.com/logrotate/logrotate): the venerable but still useful versatile logrotator
    - [bash](https://www.gnu.org/software/bash/): the venerable shell
    - [forego](https://github.com/ddollar/forego): *foreman in go*, supervisord/runit/circus/foreman alike
    - [dockerize](https://github.com/jwilder/dockerize): tool to orchestrate containers between themselves
    - [gosu](https://github.com/tianon/gosu): tool to downgrade privileges, the perfect SUDO.
    - Except for alpine based images (using musl, so no locales): setup sensible locales for: ``fr``, ``en``, ``de``.
- Wrapped images:
    - [library/golang](https://hub.docker.com/_/golang)([./library/golang](./library/golang))         ➡️ [corpusops/golang](https://hub.docker.com/r/corpusops/golang)
    - [library/php](https://hub.docker.com/_/php)([./library/php](./library/php))                     ➡️ [corpusops/php](https://hub.docker.com/r/corpusops/php)
    - [library/python](https://hub.docker.com/_/python)([./library/python](./library/python))         ➡️ [corpusops/python](https://hub.docker.com/r/corpusops/python)
    - [library/ruby](https://hub.docker.com/_/ruby)([./library/ruby](./library/ruby))                 ➡️ [corpusops/ruby](https://hub.docker.com/r/corpusops/ruby)
    - [library/mysql](https://hub.docker.com/_/mysql)([./library/mysql](./library/mysql))             ➡️ [corpusops/mysql](https://hub.docker.com/r/corpusops/mysql)
    - [mdillon/postgis](https://hub.docker.com/mdillon/postgis)([./mdillon/postgis](./mdillon/postgis))     ➡️ [corpusops/postgis](https://hub.docker.com/r/corpusops/postgis)
    - [makinacorpus/pgrouting](https://hub.docker.com/makinacorpus/pgrouting)([./makinacorpus/pgrouting](./makinacorpus/pgrouting))     ➡️ [corpusops/pgrouting](https://hub.docker.com/r/corpusops/pgrouting)
    - [library/postgres](https://hub.docker.com/_/postgres)([./library/postgres](./library/postgres)) ➡️ [corpusops/postgres](https://hub.docker.com/r/corpusops/postgres)
    - [library/nginx](https://hub.docker.com/_/nginx)([./library/nginx](./library/nginx))             ➡️ [corpusops/nginx](https://hub.docker.com/r/corpusops/nginx)
        - also add **htpasswd**
    - [library/ubuntu](https://hub.docker.com/_/ubuntu)([./library/ubuntu](./library/ubuntu))         ➡️ [corpusops/ubuntu-bare](https://hub.docker.com/r/corpusops/ubuntu-bare)
    - [library/debian](https://hub.docker.com/_/debian)([./library/debian](./library/debian))         ➡️ [corpusops/debian-bare](https://hub.docker.com/r/corpusops/debian-bare)
    - [library/alpine](https://hub.docker.com/_/alpine)([./library/alpine](./library/alpine))         ➡️ [corpusops/alpine-bare](https://hub.docker.com/r/corpusops/alpine-bare)
    - [library/fedora](https://hub.docker.com/_/fedora)([./library/fedora](./library/fedora))         ➡️ [corpusops/fedora-bare](https://hub.docker.com/r/corpusops/fedora-bare)
    - [library/centos](https://hub.docker.com/_/centos)([./library/centos](./library/centos))         ➡️ [corpusops/centos-bare](https://hub.docker.com/r/corpusops/centos-bare)
    - [library/suse](https://hub.docker.com/_/suse)([./library/suse](./library/suse))         ➡️ [corpusops/suse-bare](https://hub.docker.com/r/corpusops/suse-bare)


## Refresh some files in this repository
- Think time to time to refresh ``cops_pkgmgr_install.sh`` comes from [corpusops.bootstrap/bin](https://github.com/corpusops/corpusops.bootstrap/blob/master/bin/cops_pkgmgr_install.sh)

## Support development
- Ethereum: ``0xa287d95530ba6dcb6cd59ee7f571c7ebd532814e``
- Bitcoin: ``3GH1S8j68gBceTeEG5r8EJovS3BdUBP2jR``
- [paypal](https://paypal.me/kiorky)

