# Shared generated CSS/JS cache — no image rebuild

Confirmed owner evidence: three web Pods have identical imageID and writable cache
directories, but ModuleJS_3d7fcdd6d1ca159382520fd8f7ca35c8.js exists on only two.
HTML can reference a file on PodA, while its asset request reaches PodB and gets
404 HTML. MIME checking correctly rejects that HTML as JavaScript. Native login
starts disabled until its JS initializer enables the form, explaining inert login.

Redis remains the application cache. Generated asset FILES need separate shared
storage. This patch mounts a NEW Longhorn1Gi RWX claim into only js-cache and
Agent/default+Customer/default css-cache. Add every custom skin with --skin.
It does not mount application source, move credentials or replace existing
database/Redis/attachment/configuration volumes. No application schema migration,
Redis flush or source-image rebuild. Cache bytes are generated after page requests;
no old per-Pod cache is baked into the image or copied as authoritative data.

## 1. Prepare and review

On your Kubernetes administration host, from the extracted toolkit root:

```sh
umask 077
mkdir -p artifacts/shared-loader-cache
kubectl get deployment tessera-web -n tessera -o json \
  > artifacts/shared-loader-cache/web-before.json
kubectl get pods -n tessera -l app=tessera-web \
  -o custom-columns='POD:.metadata.name,IMAGE_ID:.status.containerStatuses[*].imageID'
kubectl get storageclass longhorn

python3 scripts/loader-cache-patch.py \
  < artifacts/shared-loader-cache/web-before.json \
  > artifacts/shared-loader-cache/patch.json
```

For multiple containers, pass --container with the actual WEB container name.
The generator reuses its image and pull policy; no hardcoded180/r1/r2 image.
Example custom skin: --skin Customer/mycompany (also mount any Agent custom skins).
Review generated JSON privately. The script does not copy environment/config
values into the patch. Raw Deployment backup may contain credentials; keep it
private and outside Git. Keep immutable image tags/digests; compare imageIDs
after rollout. The tested owner runtime is UID10001/GID33; use --uid/--gid for
deliberately different matching build settings. Existing fsGroup is preserved,
or33 supplied if absent; no root init or recursive chmod/chown is used.

The init container uses the same application image with /bin/sh directly,
bypassing application startup checks. It creates only its cache subdirectories
as the runtime user and checks access. Existing runtime/secret mounts/args/probes/
resources/replicas are retained by a strategic merge. Existing private cache
volumes can remain unused; do not delete volumes serving other directories.
All web replicas must use this PVC. If a daemon/prewarm task generates or cleans
these loader files, give that task the same matching cache mounts too.

## 2. Create the new RWX claim

Edit storage class/size/namespace only if needed, then:

```sh
kubectl apply --dry-run=server -f examples/shared-loader-cache/pvc.yaml
kubectl apply -f examples/shared-loader-cache/pvc.yaml
kubectl get pvc tessera-loader-cache -n tessera -w
```

Wait until Bound, then Ctrl+C to stop watching. If storage class uses delayed
binding, inspect claim/events and let a consumer schedule; do not delete an
existing claim or change data PVCs to force binding. Confirm Longhorn's RWX
share-manager/NFS support and node mount prerequisites. New1Gi capacity also
consumes configured Longhorn replica capacity. This is a new cache claim, not
reuse of your Redis claims. CSI/fsGroup must allow the nonroot runtime user to
create directories; an init permission failure needs targeted storage access
diagnosis, never chmod777 on the whole shared application volume.

## 3. Dry-run and apply the narrow Deployment patch

Use an isolated rehearsal or maintenance window. Mixed old/private-cache and
new/shared-cache Pods can still produce asset failures during rollout. Do not
claim zero downtime or rely on session affinity as the permanent fix.

```sh
kubectl patch deployment tessera-web -n tessera --type=strategic \
  --patch-file artifacts/shared-loader-cache/patch.json \
  --dry-run=server -o name

kubectl patch deployment tessera-web -n tessera --type=strategic \
  --patch-file artifacts/shared-loader-cache/patch.json
kubectl rollout status deployment/tessera-web -n tessera --timeout=300s
```

If initialization fails, inspect only the init container log:

```sh
kubectl logs -n tessera POD_NAME -c tessera-loader-cache-init
```

The generator returns JSON for kubectl patch, not a complete apply manifest.
Never apply the whole examples directory. If Helm/GitOps owns the Deployment,
make the equivalent source-of-truth change so reconciliation does not undo it.

## 4. Verify sharing, assets and login

Check the actual new mounts and init completion, then hard-refresh the page once
to generate assets into the new empty shared cache. After all replicas roll out,
the SAME filename must exist and have matching SHA256 in EVERY web Pod:

```sh
for pod in $(kubectl get pods -n tessera -l app=tessera-web \
  --field-selector=status.phase=Running -o name); do
  printf '\n%s\n' "$pod"
  kubectl exec -n tessera "$pod" -- sh -c '
    id
    ls -ld /opt/otobo/var/httpd/htdocs/js/js-cache
    find /opt/otobo/var/httpd/htdocs/js/js-cache -maxdepth 1 \
      -name "ModuleJS_3d7fcdd*" -exec sha256sum {} \;
  '
done
```

If the current page references a different hashed filename, check that exact
filename instead. In browser Network verify JS/CSS return200 with JavaScript/CSS
Content-Type, no404/HTML responses and Sign In actually submits. Retain nosniff;
do not force-enable a disabled form or change MIME headers to hide missing files.
Verify session/login/agent/customer/attachments across all replicas. Replace one
web Pod in an approved test window and repeat asset checks to prove cache remains
available after Pod replacement. No automated Pod deletion is performed here.

Storage subPath mounts are used for NON-SECRET cache subdirectories. Keep whole
directory Secret mounts for live credential updates. NFS file locking/concurrent
native Loader writes must be checked on the actual Longhorn volume. Avoid global
loader-cache cleanup during traffic/mixed-version rollout; refresh/regenerate
under a controlled plan. All replicas should run compatible immutable code/config.
Monitor cache capacity and define a controlled cleanup policy separately.

## 5. Rollback

Record the pre-change ReplicaSet/revision and keep the private Deployment backup.
If needed, revert this Deployment change through your deployment manager or a
reviewed kubectl rollout undo. That returns the earlier per-Pod cache layout,
which can reintroduce the ORIGINAL login problem; rollback is not its solution.
Keep the new cache PVC while any Pod references it. Do not delete or modify
Redis, MariaDB, attachments or generated-configuration PVCs for this cache fix.
