#!/usr/bin/env bash
set -e
SDEBUG=${SDEBUG-}
export SSL_COMMON_NAME="${SSL_COMMON_NAME:-"$(hostname -f)"}"
SSL_ALT_NAMES="${SSL_ALT_NAMES:-""}"
for cn in "$SSL_COMMON_NAME" "www.$SSL_COMMON_NAME";do
    if ( echo $SSL_ALT_NAMES | xargs -n1 | grep -E -qv "^$cn" );then
        SSL_ALT_NAMES="$SSL_ALT_NAMES $cn"
    fi
done
export SSL_ALT_NAMES
export NO_SSL_KEY="${NO_SSL_KEY-}"
export SSL_CERT=${SSL_CERT-}
export SSL_KEY="${SSL_KEY-}"
export SSL_KEY_BITS="${SSL_KEY-2048}"
export SSL_CERT_BASENAME=${SSL_CERT_BASENAME:-$SSL_COMMON_NAME}
export SSL_CERTS_PATH=${SSL_CERTS_PATH:-"/certs"}
export SSL_KEYS_PATH=${SSL_KEYS_PATH:-"$SSL_CERTS_PATH"}
export SSL_CERT_PATH=${SSL_CERT_PATH:-"${SSL_CERTS_PATH}/$SSL_CERT_BASENAME.crt"}
export SSL_KEY_PATH=${SSL_KEY_PATH:-"${SSL_CERTS_PATH}/$SSL_CERT_BASENAME.key"}
export SSL_INFINITE_VALIDATY="${SSL_INFINITE_VALIDATY:-"$((90*365))"}"
export SSL_KEY_VALIDITY=${SSL_KEY_VALIDITY:-$SSL_INFINITE_VALIDATY}
export SSL_CERT_VALIDITY=${SSL_CERT_VALIDITY:-$SSL_INFINITE_VALIDATY}
export SSL_DIR_MODE=${SSL_DIR_MODE:-"u+x,g+x,o+x"}
export SSL_CERT_MODE=${SSL_CERT_MODE:-0644}
export SSL_KEY_MODE=${SSL_KEY_MODE:-0640}

SSL_DIRECTORY=${SSL_DIRECTORY-}
if [ "x${SSL_DIRECTORY}" = "x" ];then
    for i in /etc/ssl /etc/ssl1.2 /etc/ssl1.1 /etc/ssl1.0 /etc/openssl;do
        if [ -e $i/openssl.cnf ];then
            SSL_DIRECTORY=$i
            break
        fi
    done
fi
if [ "x${SSL_DIRECTORY}" = "x" ];then
    echo "no SSL_DIRECTORY found" >&2;exit 1
else
    echo "SSL_DIRECTORY: $SSL_DIRECTORY" >&2
fi

log() { echo "$@" >&2; }
vv() { log "$@";"$@"; }
open_dir_perms() {
    ret=0
    for i in $@;do
        d="$1"
        od=""
        if [ ! -e "$d" ];then ret=1;fi
        if [ ! -d "$d" ];then d="$(dirname "$d")";fi
        while [ "x$d" != "x." ] && [ -d "$d" ] \
            && [ "x$d" != "x/" ] && [ "x$od" != "x$d" ];do
            if ! ( chmod "$SSL_DIR_MODE" "$d" );then ret=1;fi
            od="$d"
            d=$(dirname "$d")
        done
    done
    return $ret
}

gen_cert() {
    sans=""
    if [ "x$SSL_ALT_NAMES" != "x " ];then
        for i in $SSL_ALT_NAMES;do
            sans="${sans}DNS:$i,"
        done
        sans="$(echo "$sans"|sed -re "s/,$//g")"
    fi
    cp -f ${SSL_DIRECTORY}/openssl.cnf "$tmpcfg"
    printf "\n\n[SAN]\nsubjectAltName = $sans\n\n" >> $tmpcfg
    openssl req -x509 -nodes \
        -key "$SSL_KEY_PATH" \
        -subj "/C=US/ST=CA/O=Acme, Inc./CN=$SSL_COMMON_NAME/" \
        -reqexts SAN -extensions SAN \
        -config "$tmpcfg" \
        -out $SSL_CERT_PATH
}
setup_ssl() {
    if !(openssl version >/dev/null 2>&1);then
        log "try to install openssl"
        WANT_UPDATE="1" cops_pkgmgr_install.sh openssl
    fi
    cert_dir="$(dirname "$SSL_CERT_PATH")"
    key_dir="$(dirname "$SSL_CERT_PATH")"
    if [ ! -e "$cert_dir" ];then mkdir -p "$cert_dir";fi
    if [ ! -e "$key_dir" ];then mkdir -p "$key_dir";fi
    open_dir_perms "$cert_dir" "$key_dir"
    if [ ! -e "$SSL_KEY_PATH" ] && [ "x$NO_SSL_KEY" = "x" ];then
        if [ "x$SSL_KEY" != "x" ];then
            log "Using env value for $SSL_KEY_PATH"
            echo "$SSL_KEY" > "$SSL_KEY_PATH"
        else
            log "Generating SSL key: $SSL_KEY_PATH"
            openssl genrsa -des3 -passout pass:p4ssw0rd -out "$SSL_KEY_PATH".pass 2048
            openssl rsa -passin pass:p4ssw0rd -in "$SSL_KEY_PATH".pass -out "$SSL_KEY_PATH"
            rm "$SSL_KEY_PATH".pass
        fi
    fi
    if [ -e "$SSL_KEY_PATH" ];then chmod $SSL_KEY_MODE "$SSL_KEY_PATH";fi
    if [ ! -e "$SSL_CERT_PATH" ];then
        if [ "x$SSL_CERT" != "x" ];then
            log "Using env value for $SSL_CERT_PATH"
            echo "$SSL_CERT" > "$SSL_CERT_PATH"
        else
            log "Generating SSL cert: $SSL_CERT_PATH"
            tmpcfg="$(mktemp)"
            if !( gen_cert );then if [ -e "$tmpcfg" ];then rm -f "$tmpcfg";fi;fi
        fi
    fi
    if [ -e "$SSL_CERT_PATH" ];then chmod $SSL_CERT_MODE "$SSL_CERT_PATH";fi
}
if [ "x$SDEBUG" != "x" ];then set -x;fi
setup_ssl
# vim:set et sts=4 ts=4 tw=80:
