#!/usr/bin/env sh
set -e
SDEBUG="${SDEBUG-}"
DEBUG="${DEBUG:-${SDEBUG}}"
DRYRUN="${DRYRUN:-}"
log() { echo "$@">&2; }
debug() { if [ "x$DEBUG" = "x"  ];then log "$@";fi }
vv() { log "$@";    if [ "x${DRYRUN}" = "x" ];then "$@";fi; }
dvv() { debug "$@"; if [ "x${DRYRUN}" = "x" ];then "$@";fi; }
is_debian() { cat /etc/*release 2>/dev/null| egrep -iq "debian|ubuntu|mint";  }
is_suse() { test -e /etc/SuSE-brand || test -e /etc/SuSE-release; }
is_redhat() { cat /etc/*release 2>/dev/null| egrep -iq "centos|red|fedora|oracle|olinux|oh|rhel";  }
is_alpine() { echo $DISTRIB_ID | egrep -iq "alpine" || test -e /etc/alpine-release; }
is_archlinux() { cat /etc/*release 2>/dev/null| egrep -iq "arch"; }
if [ "x${SDEBUG}" != "x" ];then set -x;fi
INSTALL_LOCALES="${INSTALL_LOCALES-"
 fr_FR.UTF-8 fr_FR.ISO-8859-15 fr_FR.ISO-8859-1 fr_FR@euro.ISO-8859-15 fr_FR@euro.ISO-8859-1 \
 pt_PT.UTF-8 pt_PT.ISO-8859-15 pt_PT.ISO-8859-1 pt_PT@euro.ISO-8859-15 pt_PT@euro.ISO-8859-1 \
 es_ES.UTF-8 es_ES.ISO-8859-15 es_ES.ISO-8859-1 es_ES@euro.ISO-8859-15 es_ES@euro.ISO-8859-1 \
 fr_BE.UTF-8 fr_BE.ISO-8859-15 fr_BE.ISO-8859-1 fr_BE@euro.ISO-8859-15 fr_BE@euro.ISO-8859-1 \
 nl_BE.UTF-8 nl_BE.ISO-8859-15 nl_BE.ISO-8859-1 nl_BE@euro.ISO-8859-15 nl_BE@euro.ISO-8859-1 \
 nl_NL.UTF-8 nl_NL.ISO-8859-15 nl_NL.ISO-8859-1 nl_NL@euro.ISO-8859-15 nl_NL@euro.ISO-8859-1 \
 en_IE.UTF-8 en_GB.ISO-8859-15 en_GB.ISO-8859-1 \
 en_IE.UTF-8 en_IE.ISO-8859-15 en_IE.ISO-8859-1 en_IE@euro.ISO-8859-15 en_IE@euro.ISO-8859-1 \
 en_US.UTF-8 en_US.ISO-8859-15 en_US.ISO-8859-1 \
 de_DE.UTF-8 de_DE.ISO-8859-15 de_DE.ISO-8859-1 de_DE@euro.ISO-8859-15 de_DE@euro.ISO-8859-1 \
 zh_CN.UTF-8 zh_CN \
"}"
if ( is_redhat );then
     OS_ENV="/etc/sysconfig/locale"
else
     OS_ENV="/etc/default/locale"
fi
LOCALEENVSFILES="${LOCALEENVSFILES-"${OS_ENV} /etc/environment"}"
INSTALL_DEFAULT_LOCALE="${INSTALL_DEFAULT_LOCALE-}"
ALL_DEFAULT_LANG="${ALL_DEFAULT_LANG-"
LANG           LC_CTYPE           LC_NUMERIC LC_TIME    LC_COLLATE   LC_MONETARY
LC_MESSAGES    LC_PAPER           LC_NAME    LC_ADDRESS LC_TELEPHONE
LC_MEASUREMENT LC_IDENTIFICATION
"}"
log INSTALL_LOCALES: "$( echo ${INSTALL_LOCALES} )"
log INSTALL_DEFAULT_LOCALE: "$( echo ${INSTALL_DEFAULT_LOCALE-} )"
if ( is_alpine );then
    echo "No locale on alpine"
    exit 0
fi
log "Installing $INSTALL_LOCALES"
lgen() {
    for i in $@;do
        ( export LOCALEGEN="$i" && vv locale-gen $i )
    done
}

sanitize_locale() {
    echo "$@"|tr '[:upper:]' '[:lower:]'|sed -re "s/utf-?/utf/g" -e "s/-//g"
}

lazy_localedef() {
    lazylocale=$1
    ilazylocale=$(sanitize_locale $lazylocale)
    shift
    if ( sanitize_locale "$(locale -a)"|egrep -q "^$ilazylocale$" );then
        log "Already generated: $lazylocale"
    else
        vv localedef $@ $lazylocale
    fi
}
for item in $INSTALL_LOCALES;do if [ "x$item" != "x" ] ;then
    localeo=$item
    locale=$(echo "$localeo" | sed -re "s/utf.?8/UTF-8/gi")
    lang=$(echo "$locale" | awk -F '.' '{print $1}' )
    cp="UTF-8"
    if ( echo "$locale" | grep -q "\." );then
        cp=$(  echo "$locale" | awk -F '.' '{print $2}' |sed -re "s/@.*//g" )
    fi
    variant=""
    if ( echo "$locale" | grep -q "@" );then
        variant="@$(echo $locale|sed -re "s/.*@//g")"
    fi
    if ( is_debian );then
        vv touch /etc/locale.gen
        if ! ( egrep -iq "^${lang}.*${variant}.*${cp}" /etc/locale.gen );then
            log "Adding $lang $cp $variant to gen"
            cps="";if ( echo "$cp" | grep -ivq 'iso' );then cps=".${cp}";fi
            echo "${lang}${variant} ${cp}" >> /etc/locale.gen
        fi
    fi
    lazy_localedef $locale -i $lang -c -f $cp
    if [ "x${localeo}" != "x$locale" ];then
        lazy_localedef $localeo  -i $lang -c -f $cp
    fi
fi;done
if [ "x${INSTALL_DEFAULT_LOCALE}" != "x" ];then
    if ( update-locale --help >/dev/null 2>&1 );then
        vv update-locale LANG="$INSTALL_DEFAULT_LOCALE"
    fi
    touch "$OS_ENV"
    for localesenv in $LOCALEENVSFILES;do
        if [ -e "$localesenv" ];then
            log "Verifying $localesenv ($INSTALL_DEFAULT_LOCALE)"
            for knob in $ALL_DEFAULT_LANG;do
                if ! ( egrep -q "^(export +)?$knob=" "$localesenv" );then
                    log "Installing $knob in $localesenv"
                    if [ "x$localesenv" = "x/etc/environment" ];then
                        echo "$knob=$INSTALL_DEFAULT_LOCALE" >> "$localesenv"
                    else
                        echo "export $knob=$INSTALL_DEFAULT_LOCALE" >> "$localesenv"
                    fi
                else
                    log "Patching $knob in $localesenv"
                    if [ "x$localesenv" = "x/etc/environment" ];then
                        sed -i -re "s/^$knob=.*/$knob=$INSTALL_DEFAULT_LOCALE/g" "$localesenv"
                    else
                        sed -i -re "s/^(export +)?$knob=.*/export $knob=$INSTALL_DEFAULT_LOCALE/g" "$localesenv"
                    fi
                fi
            done
        fi
    done
fi
# vim:set et sts=4 ts=4 tw=0:
