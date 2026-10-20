# Complete TESSERA application image kit — Ubuntu26.04

Image revision **0.0.180-r1** fixes packaged definition permissions and RWX/NFS
configuration copying. Application Build180 stays unchanged. See
[revision r1 instructions and Longhorn tests](examples/CONFIGURE-R1.md).

Updated serving mode: **Apache 2.4 + mod_perl + mpm_prefork**, matching the supplied
host configuration. Apache serves internal HTTPS/mTLS on8443 directly. Read
[HTTPS and Pod hardening](examples/HARDENING.md) before running the web container.
The optional Nginx image is a separate migration alternative, not the default.

This kit builds the application image from your ALREADY INSTALLED /opt/otobo.
It does not reinstall180, restore OPM payloads, reset the app, migrate the DB or
change the source host. It targets your Ubuntu26.04 (Resolute) and system Perl.
The resulting image is used with either `web` or `daemon`. MariaDB and Redis
remain separate services, with MariaDB planned inside Kubernetes on durable PVCs.

No image was built in this Windows workspace (no Docker available). Run these
commands on the Ubuntu host. Image and real runtime acceptance remain required.

## 1. Prepare installed application source

Unpack this kit OUTSIDE /opt/otobo, enter its directory, then:

```sh
sudo apt-get update
sudo apt-get install -y --no-install-recommends rsync python3 unzip
bash scripts/prepare.sh /opt/otobo
```

Docker Engine/buildx must also be available. These prerequisite commands install
copying tools, not application dependencies; the Dockerfile installs those.
Run as root or a user with sudo access. The source code should be stable during
copying. A pre-existing `app/` is refused, so stale excluded secrets cannot survive.
There is no recursive deletion and no `--delete` operation against your app.

If you have an existing TESSERA entrypoint, preserve its exact bytes by supplying
its path during preparation:

```sh
bash scripts/prepare.sh /opt/otobo /path/to/current-tessera-entrypoint.sh
```

The wrapper delegates `web`/`daemon` to it after mounted-config/dependency checks.
Otherwise the included implementation uses native Apache/mod_perl PSGI and the native
OTOBO daemon start/status/stop commands. It preserves those two startup arguments;
it is not claimed to be an exact copy of an unavailable site-specific entrypoint.
Inspect site scripts for host paths/secrets and test their signals before release.
An optional site entrypoint overrides the default Apache launch; review it before
claiming the included Apache hardening applies to that custom launch path.

The copy preserves installed modules/templates/static assets and governance
defaults/runtime-overlay code. It excludes Config.pm and backups, host-generated
ZZZ*.pm/User overrides, private key files, customer article/VirtualFS files,
runtime queues/logs/sessions/caches and old packages. Exclusion from the image is
NOT data migration or permission to delete old data. Spools/in-progress work and
old FS attachments need the separate migration inventory and persistent storage.
Development scripts/test/ is also excluded: upstream S/MIME test samples contain
private keys. The private-key audit remains strict, including for .asc files;
runtime scripts such as the Apache preload and database schema files remain.
If preparation fails, do not run build.sh. No app/ is published until preparation
finishes successfully. A message that Config.pm is absent alone does not prove
preparation succeeded. Failed private .source.* stages can be retained for review;
the Docker context allowlist excludes them, and a retry uses a fresh stage.

Host `local/` and `vendor/` dependencies are not copied. Requirements are generated
using the installed bin/otobo.CheckModules.pl --docker-cpanfile; compiled modules
are rebuilt using the image's /usr/bin/perl. Any remaining bundled .so files
cause rejection: declare those integrations in cpanfile.extra/apt-extra.txt and
package them for the target ABI rather than copying arbitrary host binaries.

## 2. Build the entire application image

Review staged integrations for literal credentials privately, and add any
integration-specific dependencies to apt-extra.txt and cpanfile.extra. Then:

```sh
bash scripts/build.sh
# Default output: tessera:0.0.180-r1-ubuntu26.04
```

The Dockerfile starts from ubuntu:26.04, installs Ubuntu system Perl, ALL declared
CPAN runtime requirements, Apache2/mod_perl and the OS libraries needed to compile/load
them. It explicitly includes libredis-perl, libredis-fast-perl, libgd-perl,
libgd-dev, libjpeg-dev and libpng-dev plus DB/XML/TLS/LDAP/ODBC/PDF/graph dependencies.
No distro Perl packages are mixed with an official /usr/local/bin Perl image.
Ubuntu26.04 provides the requested [GD Perl package](https://packages.ubuntu.com/resolute/libgd-perl)
and [Redis Perl package](https://packages.ubuntu.com/fr/resolute/libredis-perl).
Build dependencies remain installed in this first complete image to avoid an
untested runtime-library pruning pass. Optional external commands such as browser
PDF renderers must be inventoried and added if used; Chromium's Ubuntu Snap
wrapper is not automatically a usable container renderer.

Build validates the application layout, secret-related exclusions, all declared
Perl requirements and compilation of the three Redis modules WITHOUT loading
Config.pm or contacting your DB. Build records installed Ubuntu package and Perl
versions. No CPAN `--notest`/`--force` is used. Initial CPAN/APT resolution needs
network access and is not a bit-reproducible lockfile build: pin base digest and
dependency versions or retain the resulting immutable image for release repeatability.

Optional values:

```sh
TESSERA_IMAGE=registry.example/tessera:0.0.180-r1-ubuntu26.04 \
BASE_IMAGE=ubuntu:26.04 OTOBO_UID=10001 OTOBO_GID=33 bash scripts/build.sh
docker save tessera:0.0.180-r1-ubuntu26.04 | gzip > artifacts/tessera-180-image.tar.gz
```

Do not change BASE_IMAGE to a different distribution without reworking/testing
dependencies. Choose a compatible digest/architecture for production. Runtime
Runtime defaults to otobo:www-data, UID10001/GID33;
set PVC/Secret permissions accordingly. No credentials are Docker build arguments.

## 3. Mount configuration and generate native config once

Keep /opt/otobo/Kernel/Config.pm externally mounted, with database credentials
loaded from /run/tessera-secrets/db-password and Redis configured with
PasswordSecret => redis-password. Mount the whole secret directory read-only,
without subPath. Config.pm itself can retain your existing file mount mechanism.

Native generated configuration is intentionally not copied from the host. A
shared writable volume at /opt/otobo/Kernel/Config/Files holds current generated
SysConfig, ACL and process files. The image includes source XML definitions
separately. Explicit `configure` seeds those definitions and runs native:

    Maint::Config::Rebuild --deploy-acls --deploy-processes

This command DOES update/deploy SysConfig in the configured DB, so run it only
against the intended staging/restored/existing DB during controlled initialization.
It does NOT run a fresh DB installer, package reinstall/upgrade or schema reset.
Do not run it independently in every replica. A source digest guards against
starting with a shared generated-config volume from a different source image.
Runtime administration can update generated files on that shared volume.

Example using an EXISTING isolated DB/Redis reachable from runtime Config.pm:

```sh
docker volume create tessera-config180
# Local Docker creates named volumes with the image path's ownership; verify it.
docker run --rm \
  --mount type=bind,src=/secure/tessera/Config.pm,dst=/opt/otobo/Kernel/Config.pm,readonly \
  --mount type=bind,src=/secure/tessera/secrets,dst=/run/tessera-secrets,readonly \
  --mount type=volume,src=tessera-config180,dst=/opt/otobo/Kernel/Config/Files \
  tessera:0.0.180-r1-ubuntu26.04 configure
```

Use your actual private paths and container network; this example does not create
a DB, restore business data or make the host's localhost reachable from a container.
In Kubernetes prepare correct volume ownership and multi-node RWX capability
for this shared config layout; never mount the entire /opt/otobo over image code.
An immutable config-distribution alternative requires separate implementation.

## 4. Run both services and validate

Create an isolated network, attach existing test dependencies appropriately and
repeat the SAME three mounts for web, daemon and smoke commands. Add article/
VirtualFS/spool persistent mounts where the inventory establishes durable FS use.

```sh
docker run -d --name tessera-web --network tessera-net \
  -p 8443:8443 \
  --mount type=bind,src=/secure/tessera/portal-tls,dst=/run/tessera-tls,readonly \
  --mount type=bind,src=/secure/tessera/Config.pm,dst=/opt/otobo/Kernel/Config.pm,readonly \
  --mount type=bind,src=/secure/tessera/secrets,dst=/run/tessera-secrets,readonly \
  --mount type=volume,src=tessera-config180,dst=/opt/otobo/Kernel/Config/Files \
  tessera:0.0.180-r1-ubuntu26.04 web
# Repeat the mounts/network with --name tessera-daemon and final argument daemon.
# Use final argument smoke for SELECT1, real Redis AUTH and a TTL60 cache roundtrip.
```

Create tessera-net first (`docker network create tessera-net`) if using that name;
put configure on that network too when dependencies require container DNS.
Do NOT start a second daemon against the active production DB before cutover.
Use one active daemon initially and Recreate/non-overlap deployment behavior.
Tini handles reaping; the daemon wrapper invokes native stop on SIGTERM. Allow
at least60 seconds termination grace and verify it with real long-running jobs.
Web uses Apache HTTPS/mTLS on8443, prefork, initially16 maximum workers and
MaxConnectionsPerChild1000. Measure worker memory and tune image/apache/main.conf
before production. Generate and mount the internal portal certificate first
(section5). The ingress must present its separate client certificate.

`modules` runs without Config/credentials. `ready` checks DB SELECT1 and actual
Redis authentication. `smoke` also writes/reads/deletes one nonsecret cache key.
Default Docker HEALTHCHECK checks process/socket liveness without repeatedly
writing DB/cache. Configure dependency readiness separately in Kubernetes.

## 5. Internal TESSERA PKI, separate from public ingress TLS

Public HTTPS terminates on ingress with the CUSTOMER/TRUSTED CA certificate.
TESSERA's own CA is for the private ingress-to-backend and component network.
Browsers/public customers do NOT need to trust this CA. No public certificate
is requested for the private .local names.

Run outside the image build context. Root CA key is encrypted interactively;
no passphrase is supplied in arguments, environment or a file. RSA key size is
8192 bits for CA and ALL leaves; root validity is three calendar years. Initial
leaves expire with that root. Later leaves are limited to three years and CA
expiry. SHA384 signatures; SAN/chain/purpose checks are performed after issuance.
8192-bit generation for five leaves can take several minutes.

```sh
bash scripts/pki.sh init /root/tessera-internal-pki
bash scripts/pki.sh defaults /root/tessera-internal-pki
```

Defaults produce distinct private keys/certificates:

| Identity | DNS SANs | Purpose |
| --- | --- | --- |
| portal | tessera.local, portal.tessera.local | server/client |
| daemon | daemon.tessera.local | server/client |
| redis | redis.tessera.local | server |
| db | db.tessera.local | server |
| ingress-client | no DNS; explicit client identity | client |

Each issued directory contains tls.key, tls.crt and public ca.crt. Keep ca.key
offline/in restricted custody and back up its passphrase separately. NEVER
mount ca.key into a Pod or put keys in the build kit/image/Git. Runtime leaf
keys are unencrypted files protected by permissions and encrypted Secret storage.
Set Secret group-read permissions for the relevant runtime user; do not make
keys world-readable. Certificates do not create DNS records: arrange private DNS
for these exact names, or issue additional actual service FQDN SANs before use.

The app can mount public ca.crt at /run/tessera-tls/ca.crt. Its wrapper builds a
runtime bundle of system public CAs plus the TESSERA CA, keeping public API trust.
TLS-capable Perl HTTP clients using that bundle verify certificates normally.
This does not automatically enable encryption in every client library.
For an internal Ubuntu host that should trust the CA globally, explicitly run:

```sh
bash scripts/trust-ca.sh /root/tessera-internal-pki/ca.crt
```

The global installer affects only that host. Mount the public CA and configure
verification in ingress, MariaDB/Redis and their clients separately. Trust
requires CA verification AND hostname verification; never use insecure/-k flags.

## 6. Internal TLS proxy and future component TLS

The default Apache container already terminates internal TLS; it requires no
Nginx sidecar. The following legacy optional proxy example assumes a separately
configured HTTP/Gazelle backend on5000 and is not used by the default web launch.
Do not deploy it against Apache8443 unchanged.

```sh
docker build -f Dockerfile.tlsproxy -t tessera-internal-tls:0.0.180 .
```

The proxy listens on8443, presents the portal certificate, and REQUIRES a client
certificate signed by the TESSERA CA. Mount only portal tls.crt/tls.key/ca.crt at
/run/tessera-tls; give the ingress the separate ingress-client key/certificate.
Set ingress upstream SNI to portal.tessera.local, trust the TESSERA CA and enable
upstream server-name verification. Keep its public/customer certificate separate.
Proxy template uses127.0.0.1:5000 for a same-Pod sidecar. For Docker testing use
`--network container:tessera-web` on the proxy so it shares that namespace;
publish8443 on the web container when creating it, without exposing5000 publicly.
That final within-Pod hop is HTTP; protection scope is the ingress-to-Pod/service
connection. Restrict direct access to5000. The daemon has no HTTP TLS server
automatically; its certificate is an identity for future component APIs/mTLS.

Current Build180 Redis backend provides PASSWORD authentication, not TLS argument
plumbing. The Redis certificate is ready for later server setup, but the loader/
client needs a separately tested TLS configuration enhancement before enforcing
Redis TLS. Likewise configure MariaDB server TLS and the native DB driver's CA/
hostname options, then verify an encrypted session before making DB TLS mandatory.
Future-only examples are supplied in examples/mariadb-tls.cnf,
examples/Config-mariadb-tls.pl and examples/redis-tls.conf. They are not installed
or copied into the application image. MariaDB attributes follow the native
OTOBO Database::Attribute hook and [DBD::MariaDB's TLS options](https://metacpan.org/pod/DBD%3A%3AMariaDB);
the server template follows [MariaDB's TLS configuration](https://mariadb.com/docs/server/security/encryption/data-in-transit-encryption/data-in-transit-encryption-enabling-tls-on-mariadb-server).
The native [Redis TLS constructor options](https://metacpan.org/pod/Redis) must
be explicitly passed by the backend; a mounted CA alone does not enable them.
This kit does not claim those existing clients became TLS-enabled by issuance.
Test public ingress proxy headers, trusted proxy CIDRs, absolute redirects and
client-IP auditing with the actual customer's ingress configuration.

Certificate renewal/revocation automation is NOT installed. Monitor expiry and
plan overlap/CA rollover before three years. Retain the issuance ledger securely;
use a managed internal issuer later if lifecycle automation is required.

## Release acceptance and scope

Before release: build on Ubuntu26.04; inspect source/package/Perl inventory; test
both roles and graceful shutdown; verify actual auth, cache, images/PDF/mail/search
and integrations; verify old/new attachments survive Pod and node replacement;
test internal TLS positive and wrong-name/untrusted/no-client-cert rejection.
Inspect image layers/context for secrets and record/pin image digest/signature.
No claim of image-wide secret absence replaces inspection of host-added source.

Application Build180 OPM/source is unchanged. This kit supplies the COMPLETE
Dockerfile/source-copy/dependency/startup/PKI inputs; app source is collected on
your host. It is not an already-built image or a Kubernetes production deployment.
Follow the existing migration plan for in-cluster MariaDB, persistence and cutover.

Revision r1 local verification:24 tests pass with2 POSIX-only skips on Windows
(18 source/PKI-policy tests and6 configure regression tests). Docker build runs
all8 configure regressions after USER otobo with an explicit UID check; those
Linux checks and real Longhorn acceptance remain to be executed on the build host.
Earlier PKI acceptance used a real RSA8192 leaf and disposable smaller fixture CA;
production CA and leaves explicitly use8192. Changed Bash scripts pass bash -n.
These checks do not
substitute for an actual Ubuntu Docker build, Apache runtime/TLS test, real DB/
Redis authentication or production certificate issuance on the host.
