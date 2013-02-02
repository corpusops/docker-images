#!/usr/bin/env sh
system=generic
if [ -e /etc/alpine-release ];then
    system=alpine
elif ( egrep -iq "debian|mint|ubuntu" /etc/*-release 2>/dev/null);then
    system=apt
elif ( egrep -iq "red.?hat" /etc/*-release 2>/dev/null);then
    system=redhat
elif ( egrep -iq "suse" /etc/*-release 2>/dev/null);then
    system=suse
fi
echo $system
# vim:set et sts=4 ts=4 tw=80:
