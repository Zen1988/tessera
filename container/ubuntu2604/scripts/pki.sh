#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
umask 077
KIT=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
[[ $# -ge 2 ]] || { echo 'Usage: pki.sh init|defaults|issue PKI_DIR [NAME DNS_CSV server|client|both]' >&2; exit 1; }
ACTION=$1
PKI=$(realpath -m -- "$2")
[[ "$PKI" != / && "$PKI" != "$KIT" && "$PKI" != "$KIT/"* ]] || { echo 'PKI must be outside image build context' >&2; exit 1; }
command -v openssl >/dev/null
command -v python3 >/dev/null
case "$ACTION" in
init)
    [[ ! -e "$PKI/ca.key" && ! -e "$PKI/ca.crt" ]] || { echo 'CA already exists; refusing replacement' >&2; exit 1; }
    mkdir -p "$PKI/newcerts" "$PKI/issued"
    chmod 0700 "$PKI" "$PKI/newcerts" "$PKI/issued"
    # Interactive encryption prompt: no passphrase in arguments/environment/logs.
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:8192 -aes-256-cbc -out "$PKI/ca.key"
    DAYS=$(python3 - <<'PY'
from datetime import datetime,timezone
now=datetime.now(timezone.utc)
try: end=now.replace(year=now.year+3)
except ValueError: end=now.replace(year=now.year+3,day=28)
print((end-now).days)
PY
)
    openssl req -new -x509 -sha384 -days "$DAYS" -key "$PKI/ca.key" \
        -subj '/O=TESSERA/CN=TESSERA Internal Root CA' \
        -addext 'basicConstraints=critical,CA:TRUE,pathlen:0' \
        -addext 'keyUsage=critical,keyCertSign,cRLSign' \
        -addext 'subjectKeyIdentifier=hash' -out "$PKI/ca.crt"
    : > "$PKI/index.txt"
    openssl rand -hex 16 > "$PKI/serial"
    cat > "$PKI/openssl.cnf" <<'CONF'
[ ca ]
default_ca = tessera
[ tessera ]
dir = $ENV::TESSERA_PKI_DIR
database = $dir/index.txt
new_certs_dir = $dir/newcerts
certificate = $dir/ca.crt
private_key = $dir/ca.key
serial = $dir/serial
default_md = sha384
default_days = 1095
unique_subject = no
copy_extensions = none
policy = identity
[ identity ]
organizationName = optional
commonName = supplied
CONF
    chmod 0600 "$PKI/ca.key"
    chmod 0644 "$PKI/ca.crt"
    openssl x509 -in "$PKI/ca.crt" -noout -fingerprint -sha256 -dates
    printf 'CA created outside kit. Back up encrypted ca.key/passphrase separately; distribute only ca.crt.\n'
    ;;
defaults)
    bash "$0" issue "$PKI" portal 'tessera.local,portal.tessera.local' both
    bash "$0" issue "$PKI" daemon 'daemon.tessera.local' both
    bash "$0" issue "$PKI" redis 'redis.tessera.local' server
    bash "$0" issue "$PKI" db 'db.tessera.local' server
    bash "$0" issue "$PKI" ingress-client '-' client
    ;;
issue)
    [[ $# == 5 ]] || { echo 'Usage: pki.sh issue PKI_DIR NAME DNS_CSV server|client|both' >&2; exit 1; }
    NAME=$3; DNS=$4; PURPOSE=$5
    [[ "$NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$ ]] || { echo 'Invalid identity name' >&2; exit 1; }
    [[ "$PURPOSE" == server || "$PURPOSE" == client || "$PURPOSE" == both ]] || { echo 'Invalid certificate purpose' >&2; exit 1; }
    [[ -s "$PKI/ca.key" && -s "$PKI/ca.crt" && -s "$PKI/openssl.cnf" ]] || { echo 'Run init first' >&2; exit 1; }
    exec 9>"$PKI/.issue.lock"
    flock -x 9
    DEST="$PKI/issued/$NAME"
    [[ ! -e "$DEST" ]] || { echo 'Identity output exists; use a new output name for renewal' >&2; exit 1; }
    mkdir -m 0700 "$DEST"
    python3 - "$DNS" "$PURPOSE" "$DEST/extensions.cnf" <<'PY'
import re,sys
dns,purpose,path=sys.argv[1:]
names=[] if dns=='-' else dns.split(',')
if (not names and purpose!='client') or any(
    len(name)>253 or any(not re.fullmatch(r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?',label)
    for label in name.split('.')) for name in names):
    raise SystemExit('Invalid DNS SAN list')
eku={'server':'serverAuth','client':'clientAuth','both':'serverAuth,clientAuth'}[purpose]
text='[leaf]\nbasicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage='+eku+'\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid,issuer\n'
if names: text+='subjectAltName='+','.join('DNS:'+name for name in names)+'\n'
with open(path,'w') as output: output.write(text)
PY
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:8192 -out "$DEST/tls.key"
    openssl req -new -sha384 -key "$DEST/tls.key" -subj "/O=TESSERA/CN=$NAME" -out "$DEST/tls.csr"
    # All initial certificates expire with the three-calendar-year root. Later
    # leaves are capped at CA expiry; none silently outlive the trust anchor.
    END=$(openssl x509 -in "$PKI/ca.crt" -noout -enddate | cut -d= -f2-)
    END=$(python3 - "$END" <<'PY'
from datetime import datetime,timezone
import sys
end=datetime.strptime(sys.argv[1],'%b %d %H:%M:%S %Y %Z').replace(tzinfo=timezone.utc)
now=datetime.now(timezone.utc)
if end<=now: raise SystemExit('CA expired')
try: cap=now.replace(year=now.year+3)
except ValueError: cap=now.replace(year=now.year+3,day=28)
print(min(end,cap).strftime('%Y%m%d%H%M%SZ'))
PY
)
    export TESSERA_PKI_DIR="$PKI"
    openssl ca -batch -notext -config "$PKI/openssl.cnf" -extensions leaf \
        -extfile "$DEST/extensions.cnf" -enddate "$END" \
        -in "$DEST/tls.csr" -out "$DEST/tls.crt"
    cp "$PKI/ca.crt" "$DEST/ca.crt"
    chmod 0600 "$DEST/tls.key"
    chmod 0644 "$DEST/tls.crt" "$DEST/ca.crt"
    VERIFY=sslserver; [[ "$PURPOSE" == client ]] && VERIFY=sslclient
    openssl verify -CAfile "$DEST/ca.crt" -purpose "$VERIFY" "$DEST/tls.crt"
    if [[ "$DNS" != '-' ]]; then
        IFS=',' read -r -a names <<< "$DNS"
        for dns in "${names[@]}"; do openssl verify -CAfile "$DEST/ca.crt" -verify_hostname "$dns" "$DEST/tls.crt"; done
    fi
    openssl x509 -in "$DEST/tls.crt" -noout -dates -serial
    printf 'Issued %s (RSA8192, validity capped at three years/CA expiry). Key is private; mount it, never build it into an image.\n' "$NAME"
    ;;
*) echo 'Unknown PKI action' >&2; exit 1 ;;
esac
