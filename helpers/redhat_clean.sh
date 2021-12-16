#!/usr/bin/env bash
set -ex
: "cleanup packages"
if (yum --help &> /dev/null );then yum clean all;fi
if (microdnf --help &> /dev/null );then microdnf clean all;fi
# vim:set et sts=4 ts=4 tw=80:
