# Opt-in Cilium 1.20 backend HTTPS for the owner's existing Gateway

Prepared from the supplied Gateway/HTTPRoute/Service, not applied to a cluster.

    Browser -- public HTTPS tessera.ncs.local:443 --> Cilium Gateway 10.0.1.72
            -- verified backend HTTPS portal.tessera.local --> Service443 --> Apache8443

Keep existing Gateway tessera-gateway, listener https, hostname tessera.ncs.local
and frontend Secret tessera-gateway-tls. No Gateway replacement or public key
material is supplied. HTTPRoute patch changes backend port only, preserving
TESSERA_ROUTE session persistence, matches and parentRefs. Backend SNI/SAN is
portal.tessera.local, independent of the browser's hostname. Ensure Config.pm
uses the intended public FQDN/HTTPS scheme for application-generated URLs.
Removing /otobo remains a separate unimplemented routing task.

The image now defaults to server-authenticated HTTPS (SSLVerifyClient none),
matching the owner's Cilium deployment decision. No Apache ConfigMap override
is needed. Cilium validates the backend CA/hostname; network policy restricts
backend access. This is not mutual TLS. HTTPS and application authentication
remain enabled; no insecure certificate verification or HTTP fallback is added.

Build the updated toolkit image once and deploy its NEW immutable tag/digest.
Old180/r1/r2 images do not change in place. Do not simply remove an override
from an old image that still contains SSLVerifyClient require. If the earlier
Apache ConfigMap override was installed, remove its Pod mount/volume after
selecting the new image; remove-apache-override-patch.yaml is provided for that
specific cleanup. Confirm container name first. The backend CA ConfigMap and
external TLS Secret are still required; they are separate from Apache config.

## 1. Prerequisites and backup

Use isolated rehearsal first or a scheduled maintenance window. Service/route/
Pod/network-policy updates are not atomic and can cause temporary outage. No
zero-downtime claim. The original web Pod spec/image/probes have not been supplied;
review them before activating. Apache must pass full startup config test and
listen8443, with controlled configure already successful on shared storage.
Update old probes pointing to80 to8443; TCP probes check listener only. Respect
matching UID10001/GID33 and all writable paths required by existing integrations.

```sh
umask 077
mkdir -p tessera-https-backup
kubectl get deployment tessera-web -n tessera -o yaml > tessera-https-backup/web.yaml
kubectl get service tessera-web -n tessera -o yaml > tessera-https-backup/service.yaml
kubectl get httproute tessera-web -n tessera -o yaml > tessera-https-backup/route.yaml
kubectl get gateway tessera-gateway -n tessera -o yaml > tessera-https-backup/gateway.yaml
kubectl get networkpolicy,ciliumnetworkpolicy -n tessera
kubectl get ciliumclusterwidenetworkpolicy
kubectl get deployment tessera-web -n tessera \
  -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'
```

Backups are private administrative files, not application source/Git inputs.
Confirm the container name in web-pod-patch.yaml matches the actual web container.
Other NetworkPolicies/Cilium policies are additive; existing broad allows can
defeat the intended restriction. Review them and test denial from unrelated Pods.
Cilium host/probe policy is cluster-dependent; test kubelet probes explicitly.
Do not add broad cluster/world access to make a failed probe pass.

## 2. Create external certificate/trust/config resources

From the extracted kit root, set PKI_DIR to your ALREADY SUCCESSFUL issuance
directory. Do not regenerate an established CA and do not load its private key.

```sh
PKI_DIR="$HOME/tessera-internal-pki"
EXAMPLES=examples/cilium-gateway
openssl verify -CAfile "$PKI_DIR/ca.crt" -purpose sslserver \
  -verify_hostname portal.tessera.local "$PKI_DIR/issued/portal/tls.crt"

kubectl create secret generic tessera-portal-tls -n tessera \
  --from-file=tls.crt="$PKI_DIR/issued/portal/tls.crt" \
  --from-file=tls.key="$PKI_DIR/issued/portal/tls.key" \
  --from-file=ca.crt="$PKI_DIR/ca.crt" --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap tessera-backend-ca -n tessera \
  --from-file=ca.crt="$PKI_DIR/ca.crt" --dry-run=client -o yaml | kubectl apply -f -

```

Only public ca.crt is put in the backend trust ConfigMap. No ingress-client key
or Apache configuration ConfigMap is needed. TLS Secrets use whole-directory
mounts; Apache certificate reload/rollout remains controlled.

## 3. Review and activate deliberately

Do NOT kubectl apply -f this directory: patch documents are not full resources.
Check installed BackendTLSPolicy API before activation:

```sh
kubectl explain backendtlspolicy --api-version=gateway.networking.k8s.io/v1
kubectl apply --dry-run=server -f "$EXAMPLES/backend-tls.yaml"
kubectl apply --dry-run=server -f "$EXAMPLES/backend-access.yaml"
kubectl patch deployment tessera-web -n tessera --type=strategic \
  --patch-file "$EXAMPLES/web-pod-patch.yaml" --dry-run=server -o yaml
kubectl patch service tessera-web -n tessera --type=merge \
  --patch-file "$EXAMPLES/service-ports-patch.yaml" --dry-run=server -o yaml
kubectl patch httproute tessera-web -n tessera --type=json \
  --patch-file "$EXAMPLES/route-port-patch.yaml" --dry-run=server -o yaml
```

The generated dry-run Deployment can contain existing literal environment values;
inspect privately and do not post credential-bearing manifests. Review the r1
image reference and probes in the Deployment separately; patches preserve them.
After rehearsal, stage controls and switch within the chosen window:

```sh
kubectl apply -f "$EXAMPLES/backend-access.yaml"
kubectl apply -f "$EXAMPLES/backend-tls.yaml"
kubectl patch deployment tessera-web -n tessera --type=strategic \
  --patch-file "$EXAMPLES/web-pod-patch.yaml"
kubectl rollout status deployment/tessera-web -n tessera --timeout=300s
kubectl patch service tessera-web -n tessera --type=merge \
  --patch-file "$EXAMPLES/service-ports-patch.yaml"
kubectl patch httproute tessera-web -n tessera --type=json \
  --patch-file "$EXAMPLES/route-port-patch.yaml"
```

The policy can interrupt current port80 traffic immediately; that is why these
commands require a rehearsal/window, not an unattended zero-outage migration.
The deployment patch does not change image tag. Confirm all serving Pods actually
use the intended new image digest and Apache configuration before final cutover.

## 4. Verify

```sh
kubectl get backendtlspolicy tessera-web-backend-tls -n tessera -o yaml
kubectl get httproute tessera-web -n tessera -o yaml
kubectl get gateway tessera-gateway -n tessera -o yaml
kubectl get service tessera-web -n tessera -o yaml
kubectl get endpointslice -n tessera -l kubernetes.io/service-name=tessera-web
```

Check current-generation Accepted/ResolvedRefs conditions (and Gateway Programmed),
endpoint port8443, Pod readiness and Apache startup logs. Status acceptance alone
is not a successful handshake. Use the trusted customer CA/system trust for the
PUBLIC endpoint; its certificate is not the private portal certificate:

```sh
curl --resolve tessera.ncs.local:443:10.0.1.72 -I https://tessera.ncs.local/
```

If frontend is privately signed, add --cacert with that frontend issuer's public
CA, not blindly the TESSERA backend CA. Never use -k as acceptance. Verify login,
redirects/public hostname, static assets, uploads, agent/customer permissions and
session persistence across all replicas. Verify backend traffic encrypted and
CA/name mismatch rejected in an isolated test policy/backend, plus unrelated
Pod access denied by Cilium. Do not intentionally break live trust to test it.
Check trusted forwarded headers/client IP separately; this change does not
complete that application security audit or enable root URLs.

## 5. Rollback

Retain the previous working image, Pod spec, probes, Service ports, HTTPRoute and
config/DB backups. Restore these as a matching set during the window; remove only
the new policy if it blocks the previous port80 path. Do not overwrite Gateway's
public certificate, delete Redis/Longhorn PVCs or delete certificate secrets in
use. Helm/GitOps deployments should change and revert through their source of
truth rather than fighting reconciliation. Raw backups contain server-managed
metadata: prepare a clean rollback manifest/diff before applying them.

References:
- https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/backendtlspolicy/
- https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/
- https://github.com/cilium/cilium/blob/v1.20.3/operator/pkg/model/translation/envoy_cluster_mutator.go
