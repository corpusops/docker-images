#!/usr/bin/env sh
export FORCE_INSTALL=y
: "install optional packages" \
    && pkgs=$(grep -vE "^\s*#" optional_packages.txt  | tr "\n" " ") \
    && \
    DO_UPDATE="" \
    WANTED_PACKAGES="" \
    WANTED_EXTRA_PACKAGES="$pkgs" \
    ./cops_pkgmgr_install.sh
wait
# vim:set et sts=4 ts=4 tw=0:
