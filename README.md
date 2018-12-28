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
    - [cron](https://fr.wikipedia.org/wiki/Cron): isc cron on debian like, cronie on redhat, busybox cron on alpine (dcron).
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
    - [dockerize](https://github.com/jwilder/dockerize): tool to orchestrate containers between themselves
    - [gosu](https://github.com/tianon/gosu): tool to downgrade privileges, the perfect SUDO.
    - Except for alpine based images (using musl, so no locales): setup sensible locales for: ``fr``, ``en``, ``de``.

- (1): if it is packaged on the underlying distrib (eg: runit is only on alpine>3)
- debian 6 (stretch) is not supported anymore.

## Wrapped images

| original  | corpusops  | build status |
|------------|-----------|:------------:|
| [library/alpine](https://hub.docker.com/_/alpine)([./library/alpine](./library/alpine))                                       | [corpusops/alpine-bare](https://hub.docker.com/r/corpusops/alpine-bare)         | x |
| [library/centos](https://hub.docker.com/_/centos)([./library/centos](./library/centos))                                       | [corpusops/centos-bare](https://hub.docker.com/r/corpusops/centos-bare)         | x |
| [library/debian](https://hub.docker.com/_/debian)([./library/debian](./library/debian))                                       | [corpusops/debian-bare](https://hub.docker.com/r/corpusops/debian-bare)         | x |
| [library/elasticsearch](https://hub.docker.com/_/elasticsearch)([./library/elasticsearch](./library/elasticsearch))           | [corpusops/elasticsearch](https://hub.docker.com/r/corpusops/elasticsearch)     | x |
| [library/fedora](https://hub.docker.com/_/fedora)([./library/fedora](./library/fedora))                                       | [corpusops/fedora-bare](https://hub.docker.com/r/corpusops/fedora-bare)         | x |
| [library/golang](https://hub.docker.com/_/golang)([./library/golang](./library/golang))                                       | [corpusops/golang](https://hub.docker.com/r/corpusops/golang)                   | x |
| [library/mongo](https://hub.docker.com/_/mongo)([./library/mongo](./library/mongo))                                           | [corpusops/mongo](https://hub.docker.com/r/corpusops/mongo)                     | x |
| [library/mysql](https://hub.docker.com/_/mysql)([./library/mysql](./library/mysql))                                           | [corpusops/mysql](https://hub.docker.com/r/corpusops/mysql)                     | x |
| [library/nginx](https://hub.docker.com/_/nginx)([./library/nginx](./library/nginx)) ( also add **htpasswd** )                 | [corpusops/nginx](https://hub.docker.com/r/corpusops/nginx)                     | x |
| [library/php](https://hub.docker.com/_/php)([./library/php](./library/php))                                                   | [corpusops/php](https://hub.docker.com/r/corpusops/php)                         | x |
| [library/postgres](https://hub.docker.com/_/postgres)([./library/postgres](./library/postgres))                               | [corpusops/postgres](https://hub.docker.com/r/corpusops/postgres)               | x |
| [library/python](https://hub.docker.com/_/python)([./library/python](./library/python))                                       | [corpusops/python](https://hub.docker.com/r/corpusops/python)                   | x |
| [library/ruby](https://hub.docker.com/_/ruby)([./library/ruby](./library/ruby))                                               | [corpusops/ruby](https://hub.docker.com/r/corpusops/ruby)                       | x |
| [library/solr](https://hub.docker.com/_/solr)([./library/solr](./library/solr))                                               | [corpusops/solr](https://hub.docker.com/r/corpusops/solr)                       | x |
| [library/suse](https://hub.docker.com/_/suse)([./library/suse](./library/suse))                                               | [corpusops/suse-bare](https://hub.docker.com/r/corpusops/suse-bare)             | x |
| [library/ubuntu](https://hub.docker.com/_/ubuntu)([./library/ubuntu](./library/ubuntu))                                       | [corpusops/ubuntu-bare](https://hub.docker.com/r/corpusops/ubuntu-bare)         | x |
| [makinacorpus/pgrouting](https://hub.docker.com/makinacorpus/pgrouting)([./makinacorpus/pgrouting](./makinacorpus/pgrouting)) | [corpusops/pgrouting](https://hub.docker.com/r/corpusops/pgrouting)             | x |
| [mdillon/postgis](https://hub.docker.com/mdillon/postgis)([./mdillon/postgis](./mdillon/postgis))                             | [corpusops/postgis](https://hub.docker.com/r/corpusops/postgis)                 | x |

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

## Support development
- Ethereum: ``0xa287d95530ba6dcb6cd59ee7f571c7ebd532814e``
- Bitcoin: ``3GH1S8j68gBceTeEG5r8EJovS3BdUBP2jR``
- [paypal](https://paypal.me/kiorky)

