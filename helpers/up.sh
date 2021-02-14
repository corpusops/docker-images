#!/usr/bin/env sh
set -e
log() { echo "${@}" >&2; }
vv() { log "${@}";"${@}"; }
DO_UPDATE=1
ARCH_BASE_PACKAGES="${ARCH_BASE_PACKAGES:-"tar gnutls systemd packer base-devel file libpsl openssl python-docutils glibc curl binutils gawk grep"}"
if [ -e /etc/arch-release ];then
    # restore locales
    sed -i -re "s/(NoExt.*locale)/#\1/g" /etc/pacman.conf
    # fix archlinux baseimage minimal tools
    pacman -Sy --noconfirm
    pacman -Su --noconfirm
    pacman -S libidn2 --noconfirm
    pacman -S --noconfirm $ARCH_BASE_PACKAGES
fi
W="$(dirname $(readlink -f "$0"))"
_cops_SYSTEM=$(system_detect.sh||./system_detect.sh||"$W/system_detect.sh")
DISTRIB_ID=
DISTRIB_CODENAME=
DISTRIB_RELEASE=
oldubuntu="^(10\.|12\.|13\.|14.10|15\.|16.10|17\.04|17\.10|18\.10|19\.04|19\.10)"
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
elif [ -e /etc/redhat-release ];then
    DISTRIB_ID=$(echo $(head  /etc/issue)|awk '{print tolower($1)}')
    DISTRIB_CODENAME=$(echo $(head  /etc/issue)|awk '{print substr(substr($4,2),1,length($4)-2)}');echo $DISTRIB_RELEASE
    DISTRIB_RELEASE=$(echo $(head  /etc/issue)|awk '{print tolower($3)}')
fi
DEBIAN_OLDSTABLE=8
find /etc -name "*.reactivate" | while read f;do
    mv -fv "$f" "$(basename $f .reactivate)"
done
if ( grep -q "release 6" /etc/redhat-release >/dev/null 2>&1 );then
    NOSOCAT=1
fi
if (echo $DISTRIB_ID | egrep -iq "debian");then
    if [ "x$DISTRIB_RELEASE" = "x" ];then
        if [ -e /etc/debian_version ];then
            DISTRIB_RELEASE=$(cat /etc/debian_version|sed -re "s!/sid!!")
        fi
        if (echo $DISTRIB_RELEASE | egrep -iq squeeze );then  DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="6" ;fi
        if (echo $DISTRIB_RELEASE | egrep -iq wheezy );then   DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="7" ;fi
        if (echo $DISTRIB_RELEASE | egrep -iq jessie );then   DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="8" ;fi
        if (echo $DISTRIB_RELEASE | egrep -iq stretch );then  DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="9" ;fi
        if (echo $DISTRIB_RELEASE | egrep -iq buster );then   DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="10";fi
        if (echo $DISTRIB_RELEASE | egrep -iq bullseye );then DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="11";fi
    fi
    sed -i -re "s/(old)?oldstable/$DISTRIB_CODENAME/g" $(find /etc/apt/sources.list* -type f)
    NAPTMIRROR="http.debian.net|httpredir.debian.org|deb.debian.org"
elif ( echo $DISTRIB_ID | egrep -iq "mint|ubuntu" );then
    NAPTMIRROR="archive.ubuntu.com|security.ubuntu.com"
fi
DEBIAN_LTS_SOURCELIST="
deb http://security.debian.org/     $DISTRIB_CODENAME/updates main contrib non-free
deb-src http://security.debian.org/ $DISTRIB_CODENAME/updates main contrib non-free
"
if ( echo $_cops_SYSTEM | egrep -iq "red.?hat" ) \
    && (yum list installed fakesystemd >/dev/null 2>&1);then
    yum swap -y fakesystemd systemd
fi
fix_epel() {
    if ( echo $DISTRIB_RELEASE | egrep -iq "^(6|7)(\.|$)" ) &&\
        [ "x$(find /etc/*repos* -name '*epel*.repo' 2>/dev/null | wc -l)" != "x0" ];then
        log "Patching epel repo to use http"
        sed -i "s/https/http/" /etc/*repos*/*epel*.repo
    fi
}
PRE_PACKAGES="ca-certificates epel-release"
if ( echo $DISTRIB_ID | egrep -iq "centos|red|fedora" ) && ! ( echo $DISTRIB_ID | egrep -iq fedora );then
    fix_epel
    for pkg in $PRE_PACKAGES;do
        ( vv yum -y install $pkg || vv yum --disablerepo=epel -y install $pkg ) || /bin/true
        ( vv yum -y update  $pkg || vv yum --disablerepo=epel -y update  $pkg )
    done
    fix_epel
fi
if ( echo $DISTRIB_ID | egrep -iq "debian|mint|ubuntu" );then
    if (echo $DISTRIB_ID|egrep -iq debian);then
        sed -i -r -e '/(((squeeze)-(lts))|testing-backports)/d' \
            $( find /etc/apt/sources.list* -type f; )
    fi
    if (echo $DISTRIB_ID|egrep -iq debian) && [ $DISTRIB_RELEASE -le $DEBIAN_OLDSTABLE ];then
        # fix old debian unstable images
        sed -i -re "s!sid(/)?!$DISTRIB_CODENAME\1!" $(find /etc/apt/sources.list* -type f)
        OAPTMIRROR="archive.debian.org"
        sed -i -r -e '/-updates|security.debian.org/d' \
            $( find /etc/apt/sources.list* -type f; )
        if (echo $DISTRIB_ID|egrep -iq debian) && [ $DISTRIB_RELEASE -eq $DEBIAN_OLDSTABLE ];then
            log "Using debian LTS packages"
            echo "$DEBIAN_LTS_SOURCELIST" >> /etc/apt/sources.list
            rm -rvf /var/lib/apt/*
        fi
    fi
    if ( echo $DISTRIB_ID | egrep -iq "mint|ubuntu" ) && \
        ( echo $DISTRIB_RELEASE |egrep -iq $oldubuntu);then
        OAPTMIRROR="old-releases.ubuntu.com"
        sed -i -r \
            -e 's/^(deb.*ubuntu)\/?(.*-(security|backport|updates).*)/#\1\/\2/g' \
            -e 's!'$NAPTMIRROR'!'$OAPTMIRROR'!g' \
            $( find /etc/apt/sources.list* -type f; )
    fi
fi

if [ "x$OAPTMIRROR" != "x" ];then
    echo "Patching APT to use $OAPTMIRROR" >&2
    printf 'Acquire::Check-Valid-Until "0";\n' \
        > /etc/apt/apt.conf.d/noreleaseexpired.conf
    sed -i -r -e 's!'$NAPTMIRROR'!'$OAPTMIRROR'!g' \
        $( find /etc/apt/sources.list* -type f; )
fi
# fix broken curl if needed
curl_updated=
if ( echo $DISTRIB_ID | egrep -iq "debian|mint|ubuntu" );then
    if ( dpkg -l libcurl3 );then
        set -x
        for i in curl libcurl3;do
            if ( dpkg -l $i );then
                dpkg --purge --force-all $i
                if [ "x$curl_updated" = "x" ];then
                    apt-get update -yqq
                    curl_updated=1
                fi
            fi
        done
        if [ "x$curl_updated" != "x" ];then
            apt-get -f -yqq install && apt-get install -yqq --force-yes curl
        fi
    fi
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
if ( echo "$DISTRIB_ID $DISTRIB_RELEASE $DISTRIB_CODENAME" | egrep -iq alpine );then
    log "Upgrading alpine"
    apk upgrade --update-cache --available
fi
export FORCE_INSTALL=y
DO_UPDATE="$DO_UPDATE" WANTED_PACKAGES="$pkgs" ./cops_pkgmgr_install.sh
install_gpg
if ! ( echo foo|envsubst >/dev/null 2>&1);then
    DO_UPDATE="$DO_UPDATE" WANTED_PACKAGES="gettext" \
        ./cops_pkgmgr_install.sh
    if ! ( echo foo|envsubst >/dev/null 2>&1);then
        echo "envsubst is missing"
    fi
fi
find /etc/rsyslog.d -name "*.conf" -not -type d \
    | while read f;do mv -vf "$f" "$f.sample";done
# vim:set et sts=4 ts=4 tw=0:
