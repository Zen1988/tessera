"""Generate explicit, separate recovery permissions for the observed NCS cluster."""
import json
from pathlib import Path
import yaml

root = Path(__file__).resolve().parent
subject = [{"kind": "ServiceAccount", "name": "tessera-operator", "namespace": "apps"}]
docs = [
    {"apiVersion": "v1", "kind": "ConfigMap", "metadata": {"name": "tessera-recovery-state", "namespace": "apps"}},
    {"apiVersion": "coordination.k8s.io/v1", "kind": "Lease", "metadata": {"name": "tessera-recovery-leader", "namespace": "apps"},
     "spec": {"leaseDurationSeconds": 120}}]

def role(namespace, name, rules):
    docs.append({"apiVersion": "rbac.authorization.k8s.io/v1", "kind": "Role",
        "metadata": {"name": name, "namespace": namespace}, "rules": rules})
    docs.append({"apiVersion": "rbac.authorization.k8s.io/v1", "kind": "RoleBinding",
        "metadata": {"name": name, "namespace": namespace}, "subjects": subject,
        "roleRef": {"apiGroup": "rbac.authorization.k8s.io", "kind": "Role", "name": name}})

role("apps", "tessera-recovery-ledger", [
    {"apiGroups": [""], "resources": ["configmaps"], "resourceNames": ["tessera-recovery-state"], "verbs": ["get", "update"]},
    {"apiGroups": ["coordination.k8s.io"], "resources": ["leases"], "resourceNames": ["tessera-recovery-leader"], "verbs": ["get", "update"]}])
role("postgres", "tessera-recovery-cnpg", [
    {"apiGroups": ["batch"], "resources": ["jobs"], "verbs": ["get"]},
    {"apiGroups": ["postgresql.cnpg.io"], "resources": ["clusters"], "resourceNames": ["tessera-postgres"], "verbs": ["get", "update"]},
    {"apiGroups": [""], "resources": ["pods", "pods/log"], "verbs": ["get"]},
    {"apiGroups": [""], "resources": ["pods/exec"], "verbs": ["get", "create"]},
    {"apiGroups": [""], "resources": ["persistentvolumeclaims"], "verbs": ["get", "update"]},
    {"apiGroups": [""], "resources": ["pods/eviction"], "verbs": ["create"]}])
# Galera permission file is separate and is not required for PostgreSQL recovery.
postgres_docs = list(docs)
role("mariadb", "tessera-recovery-galera", [
    {"apiGroups": ["k8s.mariadb.com"], "resources": ["mariadbs"], "resourceNames": ["tessera-mariadb"], "verbs": ["get"]},
    {"apiGroups": [""], "resources": ["pods", "pods/log"], "verbs": ["get"]},
    {"apiGroups": [""], "resources": ["persistentvolumeclaims"], "verbs": ["get"]},
    {"apiGroups": [""], "resources": ["pods/eviction"], "verbs": ["create"]},
    {"apiGroups": [""], "resources": ["secrets"], "resourceNames": ["tessera-mariadb-root", "tessera-mariadb-ca-bundle"], "verbs": ["get"]}])
(root / "recovery-ncs-rbac.yaml").write_text(yaml.safe_dump_all(postgres_docs, sort_keys=False))
(root / "recovery-galera-rbac.yaml").write_text(yaml.safe_dump_all(docs[len(postgres_docs):], sort_keys=False))
config = {"namespace": "apps", "policies": [{"name": "postgres-recovery", "kind": "cnpg-preserve-replace",
    "namespace": "postgres", "cluster": "tessera-postgres", "expected_identity": "7697134515630092313"}]}
(root / "recovery-config-patch.json").write_text(json.dumps({"data": {"recovery.json": json.dumps(config, indent=2)}}, indent=2))
patch = {"spec": {"replicas": 2, "template": {"spec": {
    "affinity": {"$patch": "replace", "podAntiAffinity": {"requiredDuringSchedulingIgnoredDuringExecution": [{
        "labelSelector": {"matchLabels": {"app.kubernetes.io/name": "tessera-operator"}},
        "topologyKey": "kubernetes.io/hostname"}]}},
    "containers": [{"name": "observer", "image": "docker.io/library/tessera-operator:0.3.5",
                    "args": ["--recovery-config", "/etc/tessera-operator/recovery.json"]}]}}}}
(root / "recovery-deployment-patch.yaml").write_text(yaml.safe_dump(patch, sort_keys=False))
print("Recovery RBAC, config and deployment patch generated; no cluster changes.")
