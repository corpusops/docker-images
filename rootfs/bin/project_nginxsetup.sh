#!/usr/bin/env sh
set -e
create_file() { touch "$i" && chown $NGINX_USER:$NGINX_USER "$i" && chmod 640 "$i"; }
if [ "x${SDEBUG-}" = "x1" ];then set -x;fi
export SUPERVISORD_CONFIGS=${SUPERVISORD_CONFIGS-cron nginx rsyslog}
export DJANGO__HTTP_PROTECT_PASSWORD=${DJANGO__HTTP_PROTECT_PASSWORD-}
export DJANGO__DOC_PROTECT_PASSWORD=${DJANGO__DOC_PROTECT_PASSWORD-}
export DRUPAL__HTTP_PROTECT_PASSWORD=${DRUPAL__HTTP_PROTECT_PASSWORD-}
export SYMFONY__HTTP_PROTECT_PASSWORD=${SYMFONY__HTTP_PROTECT_PASSWORD-}
NGINX_CONFIG="${NGINX_CONFIG:-/etc/nginx/nginx.conf}"
NGINX_PASSWORDS_DIR="${NGINX_PASSWORDS_DIR:-/etc/htpasswd}"
NGINX_PASSWORD_FILE="${NGINX_PASSWORD_FILE:-${NGINX_PASSWORDS_DIR}/protect}"
NGINX_DOCPASSWORD_FILE="${NGINX_DOCPASSWORD_FILE:-${NGINX_PASSWORDS_DIR}/docprotect}"
NGINX_USER="${NGINX_USER-}"
VHOST_TEMPLATES="${VHOST_TEMPLATES-/etc/nginx/conf.d/default.conf}"
if [ "x${NGINX_USER}" = "x" ];then
    for i in www-data nginx root;do
        if (getent passwd $i >/dev/null 2>&1);then NGINX_USER=$i;fi
    done
fi
if [ "x${NO_NGINX_AS_ROOT}" = "x" ];then
    sed -i -re "s/user\s+.*;/user root;/g" "$NGINX_CONFIG"
fi
if [ ! -e "$NGINX_PASSWORDS_DIR" ];then
    mkdir -pv "${NGINX_PASSWORDS_DIR}"
fi
create_file "$NGINX_PASSWORD_FILE"
create_file "$NGINX_DOCPASSWORD_FILE"
# retrocompat
for i in $(find /etc/htpasswd -type f -maxdepth 1);do ln -sfv $i /etc/htpasswd-$(basename $i);done
#
if [ "x$DJANGO__HTTP_PROTECT_PASSWORD" != "x" ];then
    echo "/ htpasswd: DJANGO">&2
    export DJANGO__HTTP_PROTECT_USER=${DJANGO__HTTP_PROTECT_USER:-root}
    echo "$DJANGO__HTTP_PROTECT_PASSWORD"|htpasswd -bim /etc/htpasswd-protect "$DJANGO__HTTP_PROTECT_USER"
fi
if [ "x$DJANGO__DOC_PROTECT_PASSWORD" != "x" ];then
  echo "/ htpasswd: DJANGODOC">&2
  export DJANGO__DOC_PROTECT_USER=${DJANGO__DOC_PROTECT_USER:-root}
  echo "$DJANGO__DOC_PROTECT_PASSWORD"|htpasswd -bim /etc/htpasswd/docprotect "$DJANGO__DOC_PROTECT_USER"
fi
if [ "x$DRUPAL__HTTP_PROTECT_PASSWORD" != "x" ];then
    echo "/ htpasswd: DRUPAL">&2
    export DRUPAL__HTTP_PROTECT_USER=${DRUPAL__HTTP_PROTECT_USER:-root}
    echo "$DRUPAL__HTTP_PROTECT_PASSWORD"|htpasswd -bim "$NGINX_PASSWORD_FILE" "$DRUPAL__HTTP_PROTECT_USER"
fi
if [ "x$SYMFONY__HTTP_PROTECT_PASSWORD" != "x" ];then
    export SYMFONY__HTTP_PROTECT_USER=${SYMFONY__HTTP_PROTECT_USER:-root}
    echo "/ htpasswd: SYMFONY">&2
    echo "$SYMFONY__HTTP_PROTECT_PASSWORD"|htpasswd -bim "$NGINX_PASSWORD_FILE" "$SYMFONY__HTTP_PROTECT_USER"
fi
for v in ${VHOST_TEMPLATES};do if [ -e $v ];then frep "${v}:$(basename ${v} .template)" --overwrite;fi;done
if [ "x$@" != "x" ];then
    "$@"
else
    exec /bin/supervisord.sh
fi
# vim:set et sts=4 ts=4 tw=0:
