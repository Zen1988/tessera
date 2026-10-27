"""Render the first observe-only deployment from the owner's 2026-10-22 inventory.

Run locally with PyYAML; deployment needs only kubectl and the generated YAML.
No cluster requests, credentials, protocol targets or workload mutations here.
"""
import copy
import json
from pathlib import Path
import yaml

root = Path(__file__).resolve().parent
docs = list(yaml.safe_load_all((root / "k8s.yaml").read_text()))
namespaces = ["apps", "tessera", "mariadb", "postgres", "awx", "forgejo",
              "elasticsearch", "kube-system", "mariadb-system", "redis-system",
              "cnpg-system", "elastic-system", "default"]
templates = [x for x in docs if x["kind"] in ("Role", "RoleBinding")
             and x["metadata"].get("namespace") == "apps"]
for namespace in namespaces:
    if namespace == "apps":
        continue
    for template in templates:
        item = copy.deepcopy(template)
        item["metadata"]["namespace"] = namespace
        docs.append(item)
for doc in docs:
    if doc["kind"] == "ConfigMap":
        config = json.loads(doc["data"]["config.json"])
        config["namespaces"] = namespaces
        doc["data"]["config.json"] = json.dumps(config, indent=2) + "\n"
    if doc["kind"] == "Deployment":
        spec = doc["spec"]["template"]["spec"]
        spec["containers"][0]["image"] = "docker.io/library/tessera-operator:0.3.5"
        spec["containers"][0]["imagePullPolicy"] = "Never"
        spec["affinity"] = {"nodeAffinity": {"requiredDuringSchedulingIgnoredDuringExecution": {
            "nodeSelectorTerms": [{"matchFields": [{"key": "metadata.name", "operator": "In",
                                                      "values": ["k8s.ncs.local"]}]}]}}}
        spec["tolerations"] = [{"key": "node-role.kubernetes.io/control-plane",
                               "operator": "Exists", "effect": "NoSchedule"}]
docs.insert(0, {"apiVersion": "v1", "kind": "Namespace", "metadata": {"name": "apps"}})
identities = [(x["kind"], x["metadata"].get("namespace"), x["metadata"]["name"]) for x in docs]
assert len(identities) == len(set(identities))
assert not any(x["kind"] in ("Service", "Ingress", "PersistentVolumeClaim") for x in docs)
for doc in docs:
    for rule in doc.get("rules", []):
        assert set(rule["verbs"]) <= {"get", "list"}
        assert "secrets" not in rule.get("resources", [])
output = root / "k8s-ncs-observe.yaml"
header = "# Generated from owner inventory 2026-10-22; no protocol credentials/targets.\n"
output.write_text(header + yaml.safe_dump_all(docs, sort_keys=False), encoding="utf-8")
print(output)
