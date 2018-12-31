#!/usr/bin/env sh
set -e
DISTRIB_ID=
DISTRIB_CODENAME=
DISTRIB_RELEAASE=
oldubuntu="^(10\.|12\.|13\.|14.10|15\.|16.10|17\.04)"
# oldubuntu="^(10\.|12\.|13\.|14.10|15\.|16.10|17\.04)"
NOSOCAT=""
OAPTMIRROR="${OAPTMIRROR:-}"
if [ -e /etc/lsb-release ];then
    debug "No lsb_release, sourcing manually /etc/lsb-release"
    DISTRIB_ID=$(. /etc/lsb-release;echo ${DISTRIB_ID})
    DISTRIB_CODENAME=$(. /etc/lsb-release;echo ${DISTRIB_CODENAME})
    DISTRIB_RELEASE=$(. /etc/lsb-release;echo ${DISTRIB_RELEASE})
elif [ -e /etc/os-release ];then
    DISTRIB_ID=$(. /etc/os-release;echo $ID)
    DISTRIB_CODENAME=$(. /etc/os-release;echo $VERSION)
    DISTRIB_CODENAME=$(echo $DISTRIB_CODENAME |sed -e "s/.*(\([^)]\+\))/\1/")
    DISTRIB_RELEASE=$(. /etc/os-release;echo $VERSION_ID)
fi
if ( grep -q "release 6" /etc/redhat-release >/dev/null 2>&1 );then
    NOSOCAT=1
fi
if (echo $DISTRIB_ID | egrep -iq "debian");then
    NAPTMIRROR="http.debian.net"
elif ( echo $DISTRIB_ID | egrep -iq "mint|ubuntu" );then
    NAPTMIRROR="archive.debian.org"
fi
if ( echo $DISTRIB_ID | egrep -iq "debian|mint|ubuntu" );then
    if (echo $DISTRIB_ID|egrep -iq debian);then
        sed -i -r -e '/testing-backports/d' \
            $( find /etc/apt/sources.list* -type f; )
    fi
    if (echo $DISTRIB_ID|egrep -iq debian) && [ $DISTRIB_RELEASE -lt 7 ];then
        OAPTMIRROR="archive.debian.org"
        sed -i -r -e '/-updates|security.debian.org/d' \
            $( find /etc/apt/sources.list* -type f; )
    fi
    if ( echo $DISTRIB_ID | egrep -iq "mint|ubuntu" ) && \
        ( echo $DISTRIB_RELEASE |egrep -iq $oldubuntu);then
        OAPTMIRROR="old-releases.ubuntu.com"
    fi
fi
if [ "x$OAPTMIRROR" != "x" ];then
    echo "Patchig APT to use $OAPTMIRROR" >&2
    sed -i -r -e 's!'$NAPTMIRROR'!'$OAPTMIRROR'!g' \
        $( find /etc/apt/sources.list* -type f; )
fi
install_gpg() {
    ret=1
    for i in gpg gnupg
    do
        if ( ./cops_pkgmgr_install.sh $i ) then
            ret=0
            break
        fi
    done
    return $ret
}
pkgs=$(grep -vE '^\s*#' packages.txt | tr "\n" ' ' )
# only disable socat on CENTOS 6
if [ "x$NOSOCAT" != "x" ];then pkgs=$(echo $pkgs|sed -e "s/socat//g");fi
if [ -e /etc/fedora-release ];then set -x && pkgs="$pkgs glibc";fi
export FORCE_INSTALL=y
DO_UPDATE="1" WANTED_PACKAGES="$pkgs" ./cops_pkgmgr_install.sh
install_gpg
# vim:set et sts=4 ts=4 tw=0:
