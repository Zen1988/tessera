#!/usr/bin/env bash
set -euo pipefail
[[ $# == 1 ]] || { echo 'Usage: trust-ca.sh /secure/path/ca.crt' >&2; exit 1; }
CA=$(realpath -e "$1")
openssl x509 -in "$CA" -noout -checkend 0 >/dev/null
openssl x509 -in "$CA" -noout -ext basicConstraints | grep -q 'CA:TRUE'
openssl verify -CAfile "$CA" "$CA"
openssl x509 -in "$CA" -noout -fingerprint -sha256
PRIVILEGE=(); (( EUID == 0 )) || PRIVILEGE=(sudo)
"${PRIVILEGE[@]}" install -m 0644 "$CA" /usr/local/share/ca-certificates/tessera-internal-ca.crt
"${PRIVILEGE[@]}" update-ca-certificates
echo 'Installed public TESSERA CA on this Ubuntu host. No private key is installed.'
