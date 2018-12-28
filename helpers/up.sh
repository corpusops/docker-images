#!/usr/bin/env sh
: "install packages" \
    &&
    DO_UPDATE="1" \
    WANTED_PACKAGES=$(grep -vE "^\s*#" packages.txt  | tr "\n" " ") \
    ./cops_pkgmgr_install.sh \
    && for i in gpg gnupg;do if ( ./cops_pkgmgr_install.sh $i );then break;fi;done \
    && gpg --version &>/dev/null
wait
# vim:set et sts=4 ts=4 tw=0:
