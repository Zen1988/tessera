# Apache HTTPS and container security

The default web process is Apache **2.4**, mod_perl and mpm_prefork, matching the
owner-provided zzz_tessera.conf. This is not the obsolete Apache 2.0 release.
All requests, including static assets, retain the native otobo.psgi handler and
preload. Source application files and Build 180 OPM are unchanged.

Apache uses an explicit standalone main.conf, not the host's stock default site,
CGI aliases or conf-enabled directory. Only required distro modules are enabled;
000-default and default-ssl are disabled; only tessera.conf is enabled and loaded.
autoindex/status and the event MPM are disabled. It runs as UID/GID 10001 on 8443,
without root, privileged ports or Linux capabilities. Source is root-owned.
Image build removes setuid/setgid from executables under /usr/bin and /usr/sbin.
Build tools remain for compatibility; no CIS or vulnerability-free certification
is claimed. Pin the approved image digest, scan packages/CPAN dependencies and
rebuild regularly for Ubuntu security fixes. Kernel/sysctl/firewall/AppArmor
policy belongs to cluster nodes and the platform, not image build commands.

Mount portal tls.crt, tls.key and ca.crt read-only at /run/tessera-tls. The key
must be group-readable by the runtime group (0440), never world-readable.
TLS 1.2/1.3 only; ingress must present its separate client certificate. Configure
ingress HTTPS backend port 8443, verified CA chain and SNI portal.tessera.local.
Public/customer ingress certificate remains separate. No plain HTTP fallback.
Do not expose this mTLS port as a browser endpoint without an ingress. Docker:

```sh
# Add to the existing web run command (alongside Config/secrets/config volume):
# --mount type=bind,src=/secure/tessera/portal-tls,dst=/run/tessera-tls,readonly
# -p 8443:8443
```

Native config test runs before web startup with mounted Config and certificates.
Build-time TESSERA_CONFIGTEST checks global Apache syntax without loading the
credential-dependent PSGI application or unavailable TLS files. It does NOT
validate the TLS/application includes; runtime apache2 -t must pass as well.
The daemon opens no HTTPS listener; its outbound TLS clients need explicit
library configuration. Current Redis authentication still has no TLS plumbing.

Hardening includes version minimization, TRACE/TRACK/CONNECT denial, filesystem
deny-by-default, no .htaccess, no Apache autoindex, an explicit block on PSGI's
own /otobo-web/static directory listing, request timeouts/header limits, a 50 MiB
body limit and nosniff. Tune body limits against attachments and ingress limits.
Application CSP, article sandbox and frame headers are preserved. No blanket CSP,
legacy X-XSS-Protection filter, HSTS preload or includeSubDomains is imposed.
Public HSTS belongs to the customer ingress policy. Logs omit query strings,
cookies, authorization headers and bodies; do not put credentials in URL paths.
App/integration logging still needs its own secret-redaction review.

ModSecurity/CRS blocking and rate limiting require staging with actual portal,
rich-text, YAML, upload and API traffic. They are not silently enabled with an
unversioned rules download. Use ingress limits with trusted client-IP handling;
do not ban the shared ingress IP or grant an app sudo/iptables privileges.

pod-security-patch.yaml supplies the future Deployment security context and
writable scratch mounts. It is a PATCH, not a complete production manifest.
Use the same restrictions for daemon and configure Jobs; do not apply a web
args/probe patch to a daemon. Keep generated config and historical business
files on their prepared shared/durable volumes. Additional skins and integrations
may need narrow writable paths; verify under readOnlyRootFilesystem, never make
the full /opt/otobo writable. Package installation and source editing must happen
in a new image, not through the running hardened Pod. Resource limits are initial
examples; measure prefork worker memory and upload/concurrency usage.

After rehearsal, enforce the cluster's supported version of Restricted Pod
Security Admission on the application namespace, with audit/warn first. This
is a namespace policy, not something a Dockerfile enables. Pin the policy version
to your cluster's version. Use NetworkPolicies to allow only ingress->web:8443,
application->DB/Redis/DNS and explicitly required integrations. Labels/CIDRs/CNI
support need cluster inventory; do not apply an invented deny-all policy to live
dependencies. No service-account API access is required by this loader.

Acceptance: build actual Ubuntu image; verify apache2 -M reports prefork/perl and
no event/worker/status/autoindex; verify TLS 1.2/1.3, wrong CA/name and absent client
cert rejection; verify normal portal/agent/API/upload/downloads, denied TRACE,
no static directory listing, security headers and graceful stop. Verify web and
daemon under the restricted security context, including all writable paths.
TCP liveness only checks listener health; readiness checks DB/Redis, and separate
HTTPS tests verify TLS. Secret volume updates are live files, but Apache loads
certificates at startup: renew using a controlled graceful reload or rollout,
with TLS handshakes checked afterward. No automatic certificate reload is claimed.

The /otobo removal is a separate outstanding routing change: native OTOBO 11.1
explicitly mounts /otobo in PSGI. An Apache root handler alone does not remove it.
Do not simply set ScriptAlias empty or rewrite core PSGI without validating links,
redirects, APIs, CSRF, static assets and separate portal/agent host routing.

References: [Apache SSL](https://httpd.apache.org/docs/2.4/mod/mod_ssl.html),
[response headers](https://httpd.apache.org/docs/2.4/mod/mod_headers.html),
[Kubernetes Restricted policy](https://kubernetes.io/docs/concepts/security/pod-security-standards/).
