#!/usr/bin/env bash
readlinkf() {
    if ( uname | grep -E -iq "darwin|bsd" );then
        if ( which greadlink 2>&1 >/dev/null );then
            greadlink -f "$@"
        elif ( which perl 2>&1 >/dev/null );then
            perl -MCwd -le 'print Cwd::abs_path shift' "$@"
        elif ( which python 2>&1 >/dev/null );then
            python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$@"
        fi
    else
        readlink -f "$@"
    fi
}
exec "$(dirname $(readlinkf "$0"))/main.sh" "$(basename $0 .sh)" "$@"
# vim:set et sts=4 ts=4 tw=80:
