#!/usr/bin/env bash
set -euo pipefail
cd /opt/otobo
[[ -r var/run/tessera-container-mode ]] || exit 1
MODE=$(<var/run/tessera-container-mode)
if [[ "$MODE" == daemon ]]; then
    exec /usr/bin/perl bin/otobo.Daemon.pl status >/dev/null 2>&1
fi
[[ "$MODE" == web ]] || exit 1
export TESSERA_CHECK_PORT=8443
/usr/bin/perl -MIO::Socket::INET -e 'my $s=IO::Socket::INET->new(PeerAddr=>"127.0.0.1",PeerPort=>$ENV{TESSERA_CHECK_PORT},Proto=>"tcp",Timeout=>3); exit($s ? 0 : 1)'
# Container health is process/socket liveness, not a repeated DB-write probe.
# Use `ready` for DB/Redis readiness and explicit `smoke` for cache roundtrips.
