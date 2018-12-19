#!/usr/bin/env bash
: "install packages" \
    && ./cops_pkgmgr_install.sh $(grep -vE "^\s*#" apt.txt  | tr "\n" " ") \
    && export DO_UPDATE="" \
    && for i in gpg gnupg;do if ( ./cops_pkgmgr_install.sh $i );then break;fi;done \
    && gpg --version &>/dev/null \
#
# vim:set et sts=4 ts=4 tw=0:
