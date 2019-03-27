#!/usr/bin/env sh
set -e
log() { echo "${@}" >&2; }
vv() { log "${@}";"${@}"; }
DO_UPDATE=1
ARCH_BASE_PACKAGES="${ARCH_BASE_PACKAGES:-"tar gnutls systemd packer base-devel file libpsl openssl python-docutils glibc curl binutils gawk grep"}"
if [ -e /etc/arch-release ];then
    # fix archlinux baseimage minimal tools
    pacman -Sy --noconfirm
    pacman -Su  --force --noconfirm
    pacman -S libidn2 --force --noconfirm
    pacman -S --noconfirm $ARCH_BASE_PACKAGES
fi
W="$(dirname $(readlink -f "$0"))"
_cops_SYSTEM=$(system_detect.sh||./system_detect.sh||"$W/system_detect.sh")
DISTRIB_ID=
DISTRIB_CODENAME=
DISTRIB_RELEAASE=
oldubuntu="^(10\.|12\.|13\.|14.10|15\.|16.10|17\.04)"
# oldubuntu="^(10\.|12\.|13\.|14.10|15\.|16.10|17\.04)"
NOSOCAT=""
OAPTMIRROR="${OAPTMIRROR:-}"
if [ -e /etc/lsb-release ];then
    DISTRIB_ID=$(. /etc/lsb-release;echo ${DISTRIB_ID})
    DISTRIB_CODENAME=$(. /etc/lsb-release;echo ${DISTRIB_CODENAME})
    DISTRIB_RELEASE=$(. /etc/lsb-release;echo ${DISTRIB_RELEASE})
elif [ -e /etc/os-release ];then
    DISTRIB_ID=$(. /etc/os-release;echo $ID)
    DISTRIB_CODENAME=$(. /etc/os-release;echo $VERSION)
    DISTRIB_CODENAME=$(echo $DISTRIB_CODENAME |sed -e "s/.*(\([^)]\+\))/\1/")
    DISTRIB_RELEASE=$(. /etc/os-release;echo $VERSION_ID)
elif [ -e /etc/debian_version ];then
    DISTRIB_ID=debian
    DISTRIB_CODENAME=$(head -n1  /etc/apt/sources.list | awk  '{print $3}')
    DISTRIB_RELEASE=$(echo $(head  /etc/issue)|awk '{print substr($3,1,1)}')
fi
DEBIAN_OLDSTABLE=8
DEBIAN_LTS_SOURCELIST="
deb http://security.debian.org/     $DISTRIB_CODENAME/updates main contrib non-free
deb-src http://security.debian.org/ $DISTRIB_CODENAME/updates main contrib non-free
"
if ( grep -q "release 6" /etc/redhat-release >/dev/null 2>&1 );then
    NOSOCAT=1
fi
if (echo $DISTRIB_ID | egrep -iq "debian");then
    NAPTMIRROR="http.debian.net|httpredir.debian.org"
elif ( echo $DISTRIB_ID | egrep -iq "mint|ubuntu" );then
    NAPTMIRROR="archive.ubuntu.com|security.ubuntu.com"
fi
if ( echo $_cops_SYSTEM | egrep -iq "red.?hat" ) \
    && (yum list installed fakesystemd >/dev/null 2>&1);then
    yum swap -y fakesystemd systemd
fi
if ( echo $_cops_SYSTEM | egrep -iq "red.?hat" ) \
    && ! ( echo $DISTRIB_ID | egrep -iq fedora );then
    DO_UPDATE="$DO_UPDATE" WANTED_PACKAGES="epel-release" ./cops_pkgmgr_install.sh
    DO_UPDATE=""
fi
if ( echo $DISTRIB_ID | egrep -iq "debian|mint|ubuntu" );then
    if (echo $DISTRIB_ID|egrep -iq debian);then
        sed -i -r -e '/(((squeeze)-(lts))|testing-backports)/d' \
            $( find /etc/apt/sources.list* -type f; )
    fi
    if (echo $DISTRIB_ID|egrep -iq debian) && [ $DISTRIB_RELEASE -le $DEBIAN_OLDSTABLE ];then
        OAPTMIRROR="archive.debian.org"
        sed -i -r -e '/-updates|security.debian.org/d' \
            $( find /etc/apt/sources.list* -type f; )
        if (echo $DISTRIB_ID|egrep -iq debian) && [ $DISTRIB_RELEASE -eq $DEBIAN_OLDSTABLE ];then
            log "Using debian LTS packages"
            echo "$DEBIAN_LTS_SOURCELIST" >> /etc/apt/sources.list
        fi
    fi
    if ( echo $DISTRIB_ID | egrep -iq "mint|ubuntu" ) && \
        ( echo $DISTRIB_RELEASE |egrep -iq $oldubuntu);then
        OAPTMIRROR="old-releases.ubuntu.com"
        sed -i -r -e 's!'$NAPTMIRROR'!'$OAPTMIRROR'!g' \
            $( find /etc/apt/sources.list* -type f; )
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
DISTRO_SYNC=${DISTRO_SYNC-}
if [ -e /etc/fedora-release ];then
    yumopts=""
    for opt in allowerasing best;do
        if (yum install --help 2>&1|grep -q -- --$opt);then
            yumopts="$yumopts --$opt"
        fi
    done
    if ( echo "$DISTRIB_ID $DISTRIB_RELEASE $DISTRIB_CODENAME"|egrep -iq "20|heisenbug" );then
        DISTRO_SYNC=1
    fi
    if [ "x$DISTRO_SYNC" != "x" ];then vv yum -y distro-sync;fi
    # be sure to install locales
    yum install $yumopts -y glibc-common
fi
export FORCE_INSTALL=y
DO_UPDATE="$DO_UPDATE" WANTED_PACKAGES="$pkgs" ./cops_pkgmgr_install.sh
install_gpg
if ! ( echo foo|envsubst >/dev/null 2>&1);then
    echo "envsubst is missing"
fi
if ! ( echo foo|envsubst >/dev/null 2>&1);then
    echo "envsubst is missing"
fi
# vim:set et sts=4 ts=4 tw=0:
