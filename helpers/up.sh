#!/usr/bin/env sh
DISTRIB_ID=
DISTRIB_CODENAME=
DISTRIB_RELEAASE=
oldubuntu="^(10\.|12\.|13\.|14.10|15\.|16.10|17\.)"
if [ -e /etc/lsb-release ];then
    . /etc/lsb-release
fi
if ( echo $DISTRIB_ID | egrep -iq "mint|ubuntu" );then
    if ( echo $DISTRIB_RELEASE |egrep -iq $oldubuntu);then
        sed -i -r -e 's!archive.ubuntu.com!old-releases.ubuntu.com!g' \
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
DO_UPDATE="1" \
WANTED_PACKAGES="$(grep -vE '^\s*#' packages.txt  | tr "\n" ' '; )" \
    ./cops_pkgmgr_install.sh && install_gpg
# vim:set et sts=4 ts=4 tw=0:
