#!/usr/bin/env sh
set -ex
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
oldubuntu="^(10\.|12\.|13\.|14\.|15\.|16\.|17\.|18\.10|19\.|20\.10|21\.|22\.10)"
# oldubuntu="^(10\.|12\.|13\.|14.10|15\.|16.10|17\.04)"
NOSOCAT=""
CENTOS_OLDSTABLE=8
CENTOS_OLDSTABLES="6|7|8"
# was to support latest dev release, but disabled as missing packages in epel (p7*)
CENTOS_STABLE=9999
OAPTMIRROR="${OAPTMIRROR:-}"
OYUMMIRROR="${OYUMMIRROR:-}"
NYUMMIRROR="${NYUMMIRROR:-}"
OUBUNTUMIRROR="${OUBUNTUMIRROR:-old-releases.ubuntu.com}"
ODEBIANMIRROR="${ODEBIANMIRROR:-archive.debian.org}"
NDEBIANMIRROR="${NDEBIANMIRROR:-http.debian.net|httpredir.debian.org|deb.debian.org}"
NUBUNTUMIRROR="${NUBUNTUMIRROR:-archive.ubuntu.com|security.ubuntu.com}"
IS_OLD_CENTOS_STABLE=""
SNCENTOSMIRROR="$(echo "${NCENTOSMIRROR}"|sed -re "s/\|.*//g")"
SNDEBIANMIRROR="$(echo "${NDEBIANMIRROR}"|sed -re "s/\|.*//g")"
SNUBUNTUMIRROR="$(echo "${NUBUNTUMIRROR}"|sed -re "s/\|.*//g")"
yuminstall () {
    if (yum --version >/dev/null 2>&1 );then
        ( vv yum -y install $@ || vv yum --disablerepo=epel -y install $@ ) || /bin/true
    else
        ( vv microdnf install $@ || vv yum --disablerepo=epel -y install $@ ) || /bin/true
    fi
}
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
DISTRIB_MAJOR="$(echo ${DISTRIB_RELEASE}|sed -re "s/\..*//g")"
EPEL_BASE_URL="https://dl.fedoraproject.org/pub/epel"
EPEL_RPM_URL="$EPEL_BASE_URL/epel-release-latest-${DISTRIB_MAJOR}.noarch.rpm"
DISTRIB_ARCH="x86_64"
EPEL_PACKAGES_URL="$EPEL_BASE_URL/${DISTRIB_MAJOR}/Everything/$DISTRIB_ARCH/Packages/e"
if [ "x${DISTRIB_ID}" = "xcentos" ] && ( echo  "${DISTRIB_MAJOR}" | grep -Eq "$CENTOS_OLDSTABLES");then
    IS_OLD_CENTOS_STABLE="1"
    EPEL_RPM_URL="https://archives.fedoraproject.org/pub/archive/epel/7/x86_64/Packages/e/epel-release-7-14.noarch.rpm"
    if (echo "$DISTRIB_RELEASE"|egrep -q "8|7");then
        OCENTOSMIRROR="${OCENTOSMIRROR:-mirror.centos.org}"
        NCENTOSMIRROR="${NCENTOSMIRROR:-vault.centos.org}"
    elif [ $DISTRIB_RELEASE -le $CENTOS_OLDSTABLE ];then
        OCENTOSMIRROR="${OCENTOSMIRROR:-vault.centos.org}"
        NCENTOSMIRROR="${NCENTOSMIRROR:-mirror.centos.org}"
    else
        OCENTOSMIRROR="${OCENTOSMIRROR:-mirror.centos.org}"
        NCENTOSMIRROR="${NCENTOSMIRROR:-vault.centos.org}"
    fi
    OYUMMIRROR="${OCENTOSMIRROR}"
    NYUMMIRROR="${NCENTOSMIRROR}"
    if [ "$OYUMMIRROR" != "x" ];then
        sed -i -r -e 's!'$OCENTOSMIRROR'!'$NCENTOSMIRROR'!g' $( find /etc/yum.repos.d -type f; )
    fi
    sed -i "s/^#.*baseurl=http/baseurl=http/g" $( find /etc/yum.repos.d -type f; )
    sed -i "s/^mirrorlist=http/#mirrorlist=http/g" $( find /etc/yum.repos.d -type f; )
fi
if ( grep -q amzn /etc/os-release );then
    yuminstall findutils
    if ( amazon-linux-extras help >/dev/null 2>&1 );then
        amazon-linux-extras install -y epel
    else
        if ( yum list | grep -q epel );then
            yum install -y epel-release
            yum-config-manager --enable epel
        fi
    fi
fi
if [ -e /etc/redhat-release ];then
    if [ -e /etc/fedora-release ];then
        vv yum upgrade -y --nogpg fedora-gpg-keys fedora-repos
    fi
    if [ ! -e /etc/yum.repos.d/epel.repo ];then
        if [ "x${DISTRIB_ID}" = "xcentos" ] && [ "${DISTRIB_MAJOR}" -gt $CENTOS_STABLE ];then
            EPEL_RPM_URL="$EPEL_PACKAGES_URL/$(curl -sSlL $EPEL_PACKAGES_URL 2>&1|grep epel-release|sed -re 's/.*href="([^"]+)".*/\1/')"
        fi
        curl -sSLO "$EPEL_RPM_URL"
        rpm -ivh $(pwd)/$(basename $EPEL_RPM_URL)
    fi
    if ! ( find --version >/dev/null 2>&1);then
        yuminstall findutils
    fi
fi
DEBIAN_OLDSTABLE=9
PG_DEBIAN_OLDSTABLE=10
find /etc -name "*.reactivate" | while read f;do
    mv -fv "$f" "$(basename $f .reactivate)"
done
if ( grep -q "release 6" /etc/redhat-release >/dev/null 2>&1 );then
    NOSOCAT=1
fi
if (echo $DISTRIB_ID | grep -E -iq "debian");then
    if [ "x$DISTRIB_RELEASE" = "x" ];then
        if [ -e /etc/debian_version ];then
            DISTRIB_RELEASE=$(cat /etc/debian_version|sed -re "s!/sid!!")
        fi
        if (echo $DISTRIB_RELEASE | grep -E -iq squeeze );then  DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="6" ;fi
        if (echo $DISTRIB_RELEASE | grep -E -iq wheezy );then   DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="7" ;fi
        if (echo $DISTRIB_RELEASE | grep -E -iq jessie );then   DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="8" ;fi
        if (echo $DISTRIB_RELEASE | grep -E -iq stretch );then  DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="9" ;fi
        if (echo $DISTRIB_RELEASE | grep -E -iq buster );then   DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="10";fi
        if (echo $DISTRIB_RELEASE | grep -E -iq bullseye );then DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="11";fi
        if (echo $DISTRIB_RELEASE | grep -E -iq bookworm );then DISTRIB_CODENAME="$DISTRIB_RELEASE";DISTRIB_RELEASE="12";fi
    fi
    sed -i -re "s/(old)?oldstable/$DISTRIB_CODENAME/g" $(find /etc/apt/sources.list* -type f)
    NAPTMIRROR="${NDEBIANMIRROR}"
    SNAPTMIRROR="${SNDEBIANMIRROR}"
elif ( echo $DISTRIB_ID | grep -E -iq "mint|ubuntu" );then
    NAPTMIRROR="${NUBUNTUMIRROR}"
    SNAPTMIRROR="${SNUBUNTUMIRROR}"
fi
DEBIAN_LTS_SOURCELIST="
deb http://security.debian.org/     $DISTRIB_CODENAME/updates main contrib non-free
deb-src http://security.debian.org/ $DISTRIB_CODENAME/updates main contrib non-free
"
if ( echo $_cops_SYSTEM | grep -E -iq "red.?hat" ) \
    && (yum list installed fakesystemd >/dev/null 2>&1);then
    yum swap -y fakesystemd systemd
fi
fix_epel() {
    if ( echo $DISTRIB_RELEASE | grep -E -iq "^(6|7)(\.|$)" ) &&\
        [ "x$(find /etc/*repos* -name '*epel*.repo' 2>/dev/null | wc -l)" != "x0" ];then
        log "Patching epel repo to use http"
        sed -i "s/https/http/" /etc/*repos*/*epel*.repo
    fi
}
PRE_PACKAGES="ca-certificates epel-release"
if ( echo $DISTRIB_ID | grep -E -iq "centos|red|fedora" ) && ! ( echo $DISTRIB_ID | grep -E -iq fedora );then
    fix_epel
    for pkg in $PRE_PACKAGES;do
        ( vv yum -y install $pkg || vv yum --disablerepo=epel -y install $pkg ) || /bin/true
        ( vv yum -y update  $pkg || vv yum --disablerepo=epel -y update  $pkg )
    done
    fix_epel
fi
if ( echo $DISTRIB_ID | grep -E -iq "debian|mint|ubuntu" );then
    if (echo $DISTRIB_ID|grep -E -iq debian);then
        sed -i -r -e '/(((squeeze)-(lts))|testing-backports)/d' $( find /etc/apt/sources.list* -type f; )
    fi
    if (echo $DISTRIB_ID|grep -E -iq debian) && [ $DISTRIB_RELEASE -le $DEBIAN_OLDSTABLE ];then
        # fix old debian unstable images
        sed -i -re "s!sid(/)?!$DISTRIB_CODENAME\1!" $(find /etc/apt/sources.list* -type f)
        OAPTMIRROR="${OAPTMIRROR:-$ODEBIANMIRROR}"
        sed -i -r -e '/-updates|security.debian.org/d' $( find /etc/apt/sources.list* -type f; )
        if (echo $DISTRIB_ID|grep -E -iq debian) && [ $DISTRIB_RELEASE -eq $DEBIAN_OLDSTABLE ] && [ $DEBIAN_OLDSTABLE -lt 9 ];then
            log "Using debian LTS packages"
            echo "$DEBIAN_LTS_SOURCELIST" >> /etc/apt/sources.list
            rm -rvf /var/lib/apt/*
        fi
    fi
    if ( echo $DISTRIB_ID | grep -E -iq "mint|ubuntu" ) && ( echo $DISTRIB_RELEASE |grep -E -iq $oldubuntu);then
        OAPTMIRROR="${OAPTMIRROR:-$OUBUNTUMIRROR}"
    fi
    if (echo $DISTRIB_ID|grep -E -iq debian) && [ -e $pglist ] && [ $DISTRIB_RELEASE -le $PG_DEBIAN_OLDSTABLE ] && [ -e /etc/apt/sources.list.d/pgdg.list ];then
        sed -i -re "s/apt.postgresql/apt-archive.postgresql/g" -e "s/http:/https:/g" /etc/apt/sources.list.d/pgdg.list
    fi
    if [ "x$OAPTMIRROR" != "x" ];then
        printf 'Acquire::Check-Valid-Until no;\nAPT{ Get { AllowUnauthenticated "1"; }; };\n\n'>/etc/apt/apt.conf.d/nogpgverif
        # 16.04/14.04 is not yet on old mirrors and were switched back to regular mirrors
        if (echo $DISTRIB_RELEASE |grep -E -iq "14.04|16.04|18.04");then
            echo "Patching APT to use $SNAPTMIRROR" >&2
            sed -i -r \
                -e 's/^(deb.*ubuntu)\/?(.*-(security|backport|updates).*)/#\1\/\2/g' \
                -e 's!'$OAPTMIRROR'!'$SNAPTMIRROR'!g' \
                $( find /etc/apt/sources.list* -type f; )
            echo "deb http://$SNAPTMIRROR/ubuntu/ $DISTRIB_CODENAME-security main restricted universe multiverse" >> /etc/apt/sources.list
         else
            echo "Patching APT to use $OAPTMIRROR" >&2
            sed -i -r \
                -e 's/^(deb.*ubuntu)\/?(.*-(security|backport|updates).*)/#\1\/\2/g' \
                -e 's!'$NAPTMIRROR'!'$OAPTMIRROR'!g' \
                $( find /etc/apt/sources.list* -type f; )
        fi
    fi
    if (echo $DISTRIB_RELEASE |grep -E -iq "18.04") && (grep -q cuda $(find /etc/apt/sources.list* -type f));then
        wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-keyring_1.0-1_all.deb || curl -O https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-keyring_1.0-1_all.deb
        dpkg -i cuda-keyring_1.0-1_all.deb
        sed -i -re "/cuda/d" /etc/apt/sources.list
        rm -f /etc/apt/sources.list.d/cuda-ubuntu1804-x86_64.list || true
        apt-key adv --keyserver keyserver.ubuntu.com --recv A4B469963BF863CC F60F4B3D7FA2AF80
    fi
    if ( (echo $DISTRIB_ID|grep -E -iq "mint|ubuntu" ) && ( echo $DISTRIB_RELEASE |grep -E -iq $oldubuntu); ) ||\
       ( (echo $DISTRIB_ID|grep -E -iq debian) && [ $DISTRIB_RELEASE -le $DEBIAN_OLDSTABLE ]; ) ||\
       ( (echo $DISTRIB_ID|grep -E -iq debian) && [ -e $pglist ] && [ $DISTRIB_RELEASE -le $PG_DEBIAN_OLDSTABLE ]; );then
        if (dpkg -l|grep -vq apt-transport-https);then sed -i -re "s/^(deb.*https:.*)/#\1 #httpsfix/g" $(find /etc/apt/sources.list* -type f);fi
        apt-get update || true
        if ! (apt-get install -y ca-certificates apt-transport-https apt bzip2);then
            apt-get full-upgrade -y
            apt-get install -y ca-certificates apt-transport-https apt bzip2
        fi
        sed -i -re "s/^#(.*)#httpsfix/\1/g" $(find /etc/apt/sources.list* -type f)
        apt-get update
    fi
fi
# fix broken curl if needed
curl_updated=
if ( echo $DISTRIB_ID | grep -E -iq "debian|mint|ubuntu" );then
    if ( dpkg -l libcurl3 );then
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
    if ( echo "$DISTRIB_ID $DISTRIB_RELEASE $DISTRIB_CODENAME"|grep -E -iq "20|heisenbug" );then
        DISTRO_SYNC=1
    fi
    if [ "x$DISTRO_SYNC" != "x" ];then vv yum -y distro-sync;fi
    # be sure to install locales
    yuminstall $yumopts -y glibc-common
fi
if ( echo "$DISTRIB_ID $DISTRIB_RELEASE $DISTRIB_CODENAME" | grep -E -iq alpine );then
    log "Upgrading alpine"
    apk update && apk add bash
    if !(apk upgrade --update-cache --available);then
        apk upgrade --update-cache && apk upgrade --update-cache --available
    fi
fi
./bin/fix_letsencrypt.sh
if ( echo $DISTRIB_ID | grep -E -iq "centos|red|fedora|amzn" );then
    # ensure no conflict between curl & curl-minimal
    yum install -y --allowerasing curl || yum install -y curl
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
find /etc/rsyslog.d -name "*.conf" -not -type d |while read f;do mv -vf "$f" "$f.sample";done
# Vim:set et sts=4 ts=4 tw=0:
