# Redis diagnostics for a failed release Job

Use the r2 ZIP. The original diagnostic did not run: Kubernetes reduced the
inline Perl PID expression before compilation. The shared diagnostic helper now
transports source as Base64 and decodes inside Perl, preserving literal dollars.
The regression tests reproduce the old argument failure and execute the corrected
encoded command path, including credential redaction and all probe modes.

Use only after the upgrade Job is terminal Failed, with no active Pods.
The diagnostic clones its image, mounts, UID and network configuration into
isolated staging. It never executes package hooks, claims a release, clears
journals, changes SysConfig rows, scales deployments or deletes the failed Job.

Extract the diagnostic ZIP into a new directory, verify SHA256SUMS there, run:

    python3 diagnose-redis.py \
      --namespace tessera \
      --job tessera-release-1795491815

The probe reads the mounted secret without displaying its contents, tests
authentication/database selection, and optionally reads the replication role.
It exercises SET/GET, SADD/expiry and the actual cache backend using unique
nonsecret probe keys. Keys use60second expirations where possible; cleanup is
attempted, including the uniquely registered cache namespace. Cleanup failures
are reported. It does not flush or modify existing cache entries.

Only whitelisted error classes and fixed status labels are printed. Raw Redis
exceptions, credentials, endpoint/config values and arbitrary errors are withheld.
The only application DB query counts the known SysConfig setting.

WRONGPASS/NOAUTH indicates authentication trouble; NOPERM indicates Redis command
or key ACL denial; READONLY indicates writes reached a read-only Redis endpoint.
Successful raw commands but a failed actual backend probe warrants serialization,
TTL and backend/client compatibility inspection. A successful probe does not
prove previously executed package hooks completed.

Keep the original bundle PVC, deployment state, maintenance and stopped workloads
until the release/package journal and partial native hook state are reviewed.
Do not delete the LabelPrint UPGRADING journal merely because its registry
already shows11.1.1, and do not delete the existing SysConfig default row.
