#!/usr/bin/env bash
set -e

export MH_STORAGE="${MH_STORAGE:-maildir}"
export MH_MAILDIR_PATH="${MH_MAILDIR_PATH:-/mails}"
export MH_SMTP_BIND_ADDR="${MH_SMTP_BIND_ADDR:-0.0.0.0:1025}"
export MH_API_BIND_ADDR="${MH_API_BIND_ADDR:-0.0.0.0:8025}"
export MH_UI_BIND_ADDR="${MH_UI_BIND_ADDR:-${MH_API_BIND_ADDR:-0.0.0.0:8025}}"
export MH_UI_WEB_PATH="${MH_UI_WEB_PATH:-/mailcatcher}"
export MH_AUTH_FILE="${MH_AUTH_FILE:-/home/mailhog/pw}"

if [ ! -e "$MH_MAILDIR_PATH" ];then mkdir "$MH_MAILDIR_PATH";fi
chown mailhog "$MH_MAILDIR_PATH"
pw=$(MH_AUTH_FILE="" MailHog bcrypt "${MAILCATCHER_PASSWORD:-mailcatcher}")
echo "${MAILCATCHER_USER:-mailcatcher}:$pw" > $MH_AUTH_FILE
if [[ -n $@ ]];then
    "$@"
else
    gosu mailhog MailHog "$@"
fi
# vim:set et sts=4 ts=4 tw=80:
