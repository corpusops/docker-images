#!/usr/bin/env bash
set -exo pipefail
: "cleanup packages"
rm -rf /var/cache/apk/*
# misc
find /etc/rsyslog.d -name "*.conf" -not -type d|while read f;do mv -vf "$f" "$f.sample";done
# vim:set et sts=4 ts=4 tw=80:
