#!/usr/bin/env sh
DISTRIB_ID=
DISTRIB_CODENAME=
DISTRIB_RELEAASE=
oldubuntu="^(10\.|12\.|13\.|14.10|15\.|16.10|17\.04)"
NOSOCAT=""
OLDMIRROR="old-releases.ubuntu.com"
for i in /etc/os-release /etc/lsb-release;do
    if [ -e $i ];then
        . "$i"
    fi
done
if ( grep -q "release 6" /etc/redhat-release >/dev/null 2>&1 );then
    NOSOCAT=1
fi
if ( echo $DISTRIB_ID | egrep -iq "mint|ubuntu" );then
    if ( echo $DISTRIB_RELEASE |egrep -iq $oldubuntu);then
        echo "Patchig APT to use $OLDMIRROR" >&2
        sed -i -r -e 's!archive.ubuntu.com!'$OLDMIRROR'!g' \
            $( find /etc/apt/sources.list* -type f; )
    fi
fi
install_gpg() {
    for i in gpg gnupg
    do
        if ( ./cops_pkgmgr_install.sh $i ) then
            break
        fi
    done
    gpg --version &>/dev/null
}
pkgs=$(grep -vE '^\s*#' packages.txt | tr "\n" ' ' )
# only disable socat on CENTOS 6
if [ "x$NOSOCAT" != "x" ];then pkgs=$(echo $pkgs|sed -e "s/socat//g");fi
DO_UPDATE="1" WANTED_PACKAGES="$pkgs" ./cops_pkgmgr_install.sh && install_gpg
# vim:set et sts=4 ts=4 tw=0:
