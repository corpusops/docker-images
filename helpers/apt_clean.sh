#!/usr/bin/env sh
: "cleanup packages" \
    && apt-get autoremove \
    && apt-get clean all \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/*
# vim:set et sts=4 ts=4 tw=80:
