#!/usr/bin/env bash
set -e
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
if ( echo ${DISTRIB_ID}${DISTRIB_CODENAME} | grep -E -iq ubuntutrusty ) ;then
    set -x
    sed -i -re 's/mozilla\/DST_Root_CA_X3.crt/!mozilla\/DST_Root_CA_X3.crt/' /etc/ca-certificates.conf
    dpkg-reconfigure -fnoninteractive ca-certificates
    update-ca-certificates
    set -x
fi
# vim:set et sts=4 ts=4 tw=80:
