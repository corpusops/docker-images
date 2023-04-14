#!/usr/bin/env sh
set -e
export DEBUG="${DEBUG-}"
export DB_SLEEP_TIME="${DB_SLEEP_TIME:-0.1}"
export DB_SERVICE_MODE=${DB_SERVICE_MODE-}
export DB_STARTUP_TIMEOUT="${DB_STARTUP_TIMEOUT-45s}"
export DB_MODE="${DB_MODE-postgresql}"
if ( echo "$DB_MODE" | grep -q post );then DB_MODE="postgres";fi
if ( echo "$DB_MODE" | grep -qE "maria|mysql" );then DB_MODE="mysql";fi
if ( echo $DB_MODE|grep -q mysql );then
    export MYSQL_USER=${MYSQL_USER-}
    export MYSQL_PASSWORD=${MYSQL_PASSWORD-}
    export MYSQL_HOST=${MYSQL_HOST-}
    export MYSQL_PORT=${MYSQL_PORT-}
    export MYSQL_DB=${MYSQL_DB-}
fi
if ( echo $DB_MODE|grep -q post );then
    export POSTGRES_HAS_POSTGIS="${POSTGRES_HAS_POSTGIS-}"
    export POSTGRES_USER=${POSTGRES_USER-}
    export POSTGRES_PASSWORD=${POSTGRES_PASSWORD-}
    export POSTGRES_HOST=${POSTGRES_HOST-}
    export POSTGRES_PORT=${POSTGRES_PORT-}
    export POSTGRES_DB=${POSTGRES_DB-}
fi
if [ "x${SDEBUG-}" = "x1" ];then set -x;fi

debuglog() { if [ "x$DEBUG" != "x" ];then echo "$@" >&2;fi; }

log() { echo "$@" >&2; }

vv() { log "$@";"$@"; }

wait_for_mysql() {
    flag=/tmp/started_$(echo $MYSQL_DB|sed -re "s![/:]!__!g")
    if [ -e "$flag" ];then rm -f "$flag";fi
    debuglog "Try connection to mysql: $MYSQL_DB & wait for db init" >&2
    set +x
    ( while true;do if ( \
      echo "select 1;"\
      | mysql --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --host="$MYSQL_HOST" "$MYSQL_DB" );then touch $flag && break;fi;done )&
    dockerize -wait file://$flag -timeout ${DB_STARTUP_TIMEOUT} 2>/dev/null
}

wait_for_postgres() {
    flag=/tmp/started_$(echo $POSTGRES_DB|sed -re "s![/:]!__!g")
    if [ -e "$flag" ];then rm -f "$flag";fi
    debuglog "Try connection to pgsql: $POSTGRES_DB & wait for db init"
    query="\pset pager off\n\pset tuples_only\nselect 1"
    if [ "x${POSTGRES_HAS_POSTGIS}" = "x1" ];then query="$query from spatial_ref_sys limit 1;select postgis_version();\n";fi
    ( while true;do if ( set +x && \
        printf "$query"|psql -qv ON_ERROR_STOP=1 \
        "postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB" >/dev/null );then touch $flag && break;fi;sleep ${DB_SLEEP_TIME};done; )&

    dockerize -wait file://$flag -timeout ${DB_STARTUP_TIMEOUT} 2>/dev/null
}

wait_for_zeo() {
    flag=/tmp/started_$(echo ${ZEO_ADDRESS}|sed -re "s![/:]!__!g")
    if [ -e "$flag" ];then rm -f "$flag";fi
    debuglog "Try connection to zeo: $ZEO_ADDRESS"
    ( while true;do if ( set +x && \
        echo is_up|busybox nc $(echo "${ZEO_ADDRESS}"|sed -re "s![/:]! !g") >/dev/null );then touch $flag && break;fi;sleep ${DB_SLEEP_TIME};done; )&
    dockerize -wait file://$flag -timeout ${DB_STARTUP_TIMEOUT} 2>/dev/null
}

if [ "x${DB_MODE}" != "x" ] && [ "x${SKIP_STARTUP_DB}" = "x" ]; then
    if ! ( "wait_for_${DB_MODE}"; );then log "DB not available";exit 1;fi
    if [ "x${DB_SERVICE_MODE}" = "x1" ];then
        while true;do printf "HTTP/1.1 200 OK\nContent-Length: 8\n\nstarted"| ( busybox nc -l -p 80 || /bin/true );done
    fi
fi
# vim:set et sts=4 ts=4 tw=0:
