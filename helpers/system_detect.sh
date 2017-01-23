#!/bin/sh
set -ex
system=generic 
if [ -e /etc/arch-release ];then
    system=archlinux
elif [ -e /etc/alpine-release ];then
    system=alpine
elif ( grep -E -iq "suse" $(ls /etc/ImageVersion /etc/*-release 2>/dev/null||/bin/true 2>/dev/null) 2>/dev/null);then
    system=suse
elif ( grep -E -iq "debian|mint|ubuntu" /etc/*-release 2>/dev/null);then
    system=apt
elif ( grep -E -iq "fedora|centos|ol|oracle|red.?hat" /etc/*-release 2>/dev/null);then
    system=redhat
fi
echo $system
# vim:set et sts=4 ts=4 tw=0:
