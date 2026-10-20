#!/usr/bin/env bash
set -euo pipefail
cd /opt/otobo
MODE=${1:-web}
shift || true
fail() { echo "TESSERA: $*" >&2; exit 1; }
configure() {
    [[ -r Kernel/Config.pm ]] || fail 'Mount Config.pm first'
    mountpoint -q /opt/otobo/Kernel/Config/Files || fail 'configure needs a shared generated-config volume at Kernel/Config/Files'
    cp -a /opt/tessera/config-files.dist/. /opt/otobo/Kernel/Config/Files/
    /usr/bin/perl bin/otobo.Console.pl Maint::Config::Rebuild --deploy-acls --deploy-processes
    cp /opt/tessera/config-definitions.sha256 Kernel/Config/Files/.tessera-config-definitions.sha256
}
trust_bundle() {
    if [[ -r /run/tessera-tls/ca.crt ]]; then
        openssl x509 -in /run/tessera-tls/ca.crt -noout -checkend 0 >/dev/null || fail 'Mounted TESSERA CA is invalid/expired'
        openssl x509 -in /run/tessera-tls/ca.crt -noout -ext basicConstraints | grep -q 'CA:TRUE' || fail 'Mounted trust certificate is not a CA'
        cat /etc/ssl/certs/ca-certificates.crt /run/tessera-tls/ca.crt > var/tmp/tessera-ca-bundle.pem
        export SSL_CERT_FILE=/opt/otobo/var/tmp/tessera-ca-bundle.pem
        export PERL_LWP_SSL_CA_FILE="$SSL_CERT_FILE"
    fi
}
case "$MODE" in
    modules)
        /usr/bin/perl -c Custom/Kernel/System/TESSERA/Secrets.pm
        /usr/bin/perl -c Custom/Kernel/System/TESSERA/SecretRedis.pm
        /usr/bin/perl -c Custom/Kernel/System/Cache/Redis.pm
        exec /usr/bin/perl -MGD -MRedis -MRedis::Fast -MDBD::MariaDB -MPlack::Handler::Gazelle -e 'print "Image module imports OK\n"'
        ;;
    configure) trust_bundle; configure; exit ;;
    web|daemon|ready|smoke)
        [[ -r Kernel/Config.pm ]] || fail 'Mount external Config.pm'
        for file in ZZZAAuto.pm ZZZACL.pm ZZZProcessManagement.pm; do
            [[ -r "Kernel/Config/Files/$file" ]] || fail 'Run configure once with the shared generated-config volume before startup'
        done
        cmp -s /opt/tessera/config-definitions.sha256 Kernel/Config/Files/.tessera-config-definitions.sha256 || fail 'Generated-config source differs; run the controlled configure step for this image'
        trust_bundle
        /usr/bin/perl /usr/local/lib/tessera/runtime-check.pl "$MODE"
        ;;
    *) exec "$MODE" "$@" ;;
esac
case "$MODE" in
    ready|smoke) exit 0 ;;
esac
# Optional exact site entrypoint; prepare copies it only when supplied explicitly.
printf '%s\n' "$MODE" > var/run/tessera-container-mode
if [[ -f /usr/local/lib/tessera/site-entrypoint.sh ]]; then
    exec /bin/bash /usr/local/lib/tessera/site-entrypoint.sh "$MODE" "$@"
fi
if [[ "$MODE" == web ]]; then
    [[ $# == 0 || ( $# == 1 && "$1" == deployment ) ]] || fail 'Web argument supports deployment only'
    for file in tls.crt tls.key ca.crt; do
        [[ -r "/run/tessera-tls/$file" ]] || fail 'Mount readable internal HTTPS certificate, key and CA'
    done
    mkdir -p var/run/apache
    export APACHE_RUN_DIR=/opt/otobo/var/run/apache
    export APACHE_RUN_USER=otobo APACHE_RUN_GROUP=otobo
    export APACHE_LOG_DIR=/opt/otobo/var/log APACHE_PID_FILE="$APACHE_RUN_DIR/apache.pid"
    umask 027
    /usr/sbin/apache2 -t -f /usr/local/lib/tessera/apache/main.conf
    exec /usr/sbin/apache2 -f /usr/local/lib/tessera/apache/main.conf -DFOREGROUND
fi
SLEEP_PID=''
stop_daemon() {
    trap - TERM INT
    [[ -z "$SLEEP_PID" ]] || kill "$SLEEP_PID" 2>/dev/null || true
    /usr/bin/perl bin/otobo.Daemon.pl stop || true
    exit 0
}
trap stop_daemon TERM INT
/usr/bin/perl bin/otobo.Daemon.pl start
sleep 2 & SLEEP_PID=$!; wait "$SLEEP_PID"; SLEEP_PID=''
while /usr/bin/perl bin/otobo.Daemon.pl status >/dev/null 2>&1; do
    sleep 15 & SLEEP_PID=$!; wait "$SLEEP_PID"; SLEEP_PID=''
done
fail 'Daemon stopped; exiting for the container orchestrator to restart'
