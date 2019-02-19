#!/usr/bin/env sh
set -e
if [ "x${SDEBUG}" != "x" ];then set -x;fi
AUR_USER="${AUR_USER:-aur}"
AUR_PACKAGES=${AUR_PACKAGES-$@}
AUR_MIRROR="${AUR_MIRROR:-"https://aur.archlinux.org/cgit/aur.git/snapshot"}"
AUR_BUILDDIR="${AUR_BUILDDIR:-/tmp}"
if [ -e /etc/arch-release ] && [ "x$AUR_PACKAGES" != "x" ];then
    if ! ( getent passwd $AUR_USER >/dev/null 2>&1; );then
        useradd -d "/home/$AUR_USER" -m $AUR_USER
    fi
    for pkgname in $AUR_PACKAGES;do
        pkgbuilddir="$AUR_BUILDDIR/aur-$pkgname"
        if [ ! -d $pkgbuilddir ];then
            mkdir -p "$pkgbuilddir"
        fi
        cd "$pkgbuilddir"
        curl -L $AUR_MIRROR/$pkgname.tar.gz | tar zx
        chown -R $AUR_USER .
        cd "$pkgname"
        su $AUR_USER -c "makepkg --noconfirm"
        pacman -U --noconfirm $pkgname*pkg.tar.xz
        cd /
        rm -rf "$pkgbuilddir"
    done
fi
# vim:set et sts=4 ts=4 tw=80:
