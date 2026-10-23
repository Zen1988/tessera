"""Policy-bound recovery; no PVC deletion, forced pod deletion or primary promotion.

CNPG replacement follows native destroy --keep-pvc metadata semantics (v1.30.1).
Galera rejoin restarts one failed member only with a live primary component.
Progress and leadership live in precreated Kubernetes ConfigMap/Lease, not a DB.
"""
import base64
import datetime as dt
import hashlib
import json
import os
import ssl
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

from monitor import Kube, SA, NoRedirect, MAX_BODY, age, conditions, result, utc

FENCE = "cnpg.io/fencedInstances"
DETACHED = "cnpg.io/pvcStatus"
MARK = "tessera.local/recovery-operation"
PG_SQL = """SELECT json_build_object(
'replica', pg_is_in_recovery(),
'system_id', (pg_control_system()).system_identifier::text,
'timeline', (pg_control_checkpoint()).timeline_id,
'receivers', (SELECT COALESCE(json_agg(status),'[]') FROM pg_stat_wal_receiver),
'replicas', (SELECT COALESCE(json_agg(json_build_object('name',application_name,
'state',state,'lag',pg_wal_lsn_diff(sent_lsn,replay_lsn))),'[]') FROM pg_stat_replication));"""
PG_COMMAND = ["psql", "-U", "postgres", "-d", "postgres", "-XAt", "--no-password",
              "-v", "ON_ERROR_STOP=1", "-c", "SET statement_timeout='3s'; SET default_transaction_read_only=on; " + PG_SQL]


class Blocked(Exception):
    """Only fixed, non-secret messages may be passed here."""


def is_404(exc):
    return isinstance(exc, urllib.error.HTTPError) and exc.code == 404


class API(Kube):
    def request(self, method, path, body=None):
        # Select a reachable, CA/hostname-verified endpoint using a read first.
        # Never replay a mutation after a timeout; persisted state reconciles it next cycle.
        self.get("/version")
        context = ssl.create_default_context(cafile=str(SA / "ca.crt"))
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}),
            urllib.request.HTTPSHandler(context=context), NoRedirect())
        headers = {"Authorization": "Bearer " + (SA / "token").read_text().strip(),
                   "Content-Type": "application/json", "Accept": "application/json"}
        payload = json.dumps(body).encode() if body is not None else None
        with opener.open(urllib.request.Request(self.base + path, payload, headers, method=method), timeout=4) as response:
            data = response.read(MAX_BODY + 1)
            if len(data) > MAX_BODY:
                raise Blocked("API response exceeds bounded limit")
            return json.loads(data) if data else {}

    def logs(self, namespace, pod, container, previous=True):
        self.get("/version")
        query = urllib.parse.urlencode({"container": container, "previous": str(previous).lower(),
                                       "tailLines": 120, "limitBytes": 131072})
        context = ssl.create_default_context(cafile=str(SA / "ca.crt"))
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}),
            urllib.request.HTTPSHandler(context=context), NoRedirect())
        request = urllib.request.Request(self.base + f"/api/v1/namespaces/{namespace}/pods/{pod}/log?{query}",
            headers={"Authorization": "Bearer " + (SA / "token").read_text().strip()})
        with opener.open(request, timeout=4) as response:
            return response.read(131072).decode("utf-8", errors="replace")

    def postgres(self, namespace, pod):
        self.get("/version")
        import websocket
        params = [("command", value) for value in PG_COMMAND]
        params += [("container", "postgres"), ("stdout", "true"), ("stderr", "true"),
                   ("stdin", "false"), ("tty", "false")]
        endpoint = self.base.replace("https://", "wss://", 1)
        endpoint += f"/api/v1/namespaces/{namespace}/pods/{pod}/exec?" + urllib.parse.urlencode(params)
        connection = websocket.create_connection(endpoint, timeout=4,
            header=["Authorization: Bearer " + (SA / "token").read_text().strip()],
            subprotocols=["v4.channel.k8s.io"], http_no_proxy=["*"],
            sslopt={"ca_certs": str(SA / "ca.crt"), "cert_reqs": ssl.CERT_REQUIRED,
                    "check_hostname": True})
        output, status = bytearray(), None
        end = time.monotonic() + 12
        try:
            while time.monotonic() < end:
                frame = connection.recv()
                if not frame:
                    break
                if isinstance(frame, str):
                    frame = frame.encode()
                if frame[0] == 1:
                    output.extend(frame[1:])
                    if len(output) > 65536:
                        raise Blocked("SQL output exceeds limit")
                elif frame[0] == 3:
                    status = json.loads(frame[1:])
                    break
            if status is None or status.get("status") != "Success":
                raise Blocked("PostgreSQL read-only probe failed")
            rows = [line for line in output.decode().splitlines() if line.startswith("{")]
            if len(rows) != 1:
                raise Blocked("PostgreSQL probe response is ambiguous")
            return json.loads(rows[0])
        finally:
            connection.close()

    def galera(self, policy, pod):
        import pymysql
        ns = policy["namespace"]
        ref = policy["credentials"]
        # Only exact configured Secret names are requested; never list Secrets.
        secret = self.get(f"/api/v1/namespaces/{ns}/secrets/{ref['secret']}")["data"]
        password = base64.b64decode(secret[ref["password_key"]]).decode()
        ca = self.get(f"/api/v1/namespaces/{ns}/secrets/{ref['ca_secret']}")["data"]
        # Public CA only; signing CA keys are never consumed.
        trust = base64.b64decode(ca[ref["ca_key"]])
        name = pod["metadata"]["name"]
        host = policy["member_dns"].replace("{pod}", name)
        with tempfile.TemporaryDirectory(prefix="tessera-ca-") as directory:
            ca_file = Path(directory) / "ca.crt"
            ca_file.write_bytes(trust)
            connection = pymysql.connect(host=host, port=3306, user="root", password=password,
                ssl_ca=str(ca_file), ssl_verify_cert=True, ssl_verify_identity=True,
                connect_timeout=3, read_timeout=3, write_timeout=3)
            try:
                with connection.cursor() as cursor:
                    cursor.execute("SHOW GLOBAL STATUS LIKE 'wsrep_%'")
                    values = dict(cursor.fetchall())
                return {"uuid": values.get("wsrep_cluster_state_uuid"),
                        "component": values.get("wsrep_cluster_status"),
                        "synced": values.get("wsrep_local_state_comment") == "Synced",
                        "ready": values.get("wsrep_ready") == "ON",
                        "connected": values.get("wsrep_connected") == "ON",
                        "size": int(values.get("wsrep_cluster_size", 0))}
            finally:
                connection.close()


def validate(config):
    import re
    if set(config) != {"namespace", "policies"} or config["namespace"] != "apps":
        raise ValueError("recovery requires the apps ledger namespace")
    if not isinstance(config["policies"], list) or len(config["policies"]) > 4:
        raise ValueError("at most four recovery policies supported")
    names = set()
    for policy in config["policies"]:
        if policy.get("kind") == "longhorn-stall-recovery":
            from longhorn_recovery import validate as validate_longhorn
            validate_longhorn(policy)
            if policy["name"] in names:
                raise ValueError("duplicate policy")
            names.add(policy["name"])
            continue
        if policy.get("kind") == "redis-replica-replace":
            from redis_recovery import validate as validate_redis
            validate_redis(policy)
            if policy["name"] in names:
                raise ValueError("duplicate policy")
            names.add(policy["name"])
            continue
        common = {"name", "kind", "namespace", "cluster", "expected_identity"}
        if policy.get("kind") == "galera-rejoin":
            common |= {"credentials", "member_dns"}
        elif policy.get("kind") != "cnpg-preserve-replace":
            raise ValueError("unsupported recovery kind")
        if set(policy) != common:
            raise ValueError("unexpected or missing recovery policy field")
        for key in ("name", "namespace", "cluster"):
            if not isinstance(policy[key], str) or not re.fullmatch(r"[a-z0-9][a-z0-9.-]{0,62}", policy[key]):
                raise ValueError("invalid recovery resource name")
        if policy["name"] in names or not isinstance(policy["expected_identity"], str) or not policy["expected_identity"]:
            raise ValueError("duplicate policy or missing expected identity")
        names.add(policy["name"])
        if policy["kind"] == "galera-rejoin":
            ref = policy["credentials"]
            if set(ref) != {"secret", "password_key", "ca_secret", "ca_key"}:
                raise ValueError("explicit named Secret keys required")
            if not all(isinstance(value, str) and re.fullmatch(r"[a-zA-Z0-9._-]{1,253}", value) for value in ref.values()):
                raise ValueError("invalid Secret reference")
            if not isinstance(policy["member_dns"], str) or policy["member_dns"].count("{pod}") != 1 or not re.fullmatch(r"[a-z0-9.{}-]+", policy["member_dns"]):
                raise ValueError("per-member TLS DNS template required")
    return config


class Controller:
    def __init__(self, config, api=None):
        self.config = validate(config)
        self.api = api or API()
        self.identity = str(uuid.uuid4())
        self.base = "/api/v1/namespaces/apps/configmaps/tessera-recovery-state"
        self.lease = "/apis/coordination.k8s.io/v1/namespaces/apps/leases/tessera-recovery-leader"
        self.index = 0

    def lead(self):
        lease = self.api.get(self.lease)
        spec = lease.get("spec", {})
        held = spec.get("holderIdentity")
        if held and held != self.identity and age(spec.get("renewTime")) < 120:
            raise Blocked("another recovery controller holds leadership")
        lease["spec"] = {**spec, "holderIdentity": self.identity, "leaseDurationSeconds": 120,
                         "renewTime": utc()}
        self.api.request("PUT", self.lease, lease)

    def load(self):
        obj = self.api.get(self.base)
        return obj, json.loads(obj.get("data", {}).get("state.json", "{}"))

    def save(self, obj, state):
        self.lead()
        obj.setdefault("data", {})["state.json"] = json.dumps(state)
        updated = self.api.request("PUT", self.base, obj)
        # Multiple intent/receipt writes within one cycle must use the returned CAS version.
        obj.clear()
        obj.update(updated)

    def mutate(self, method, path, body):
        # Renew/CAS leadership immediately before every bounded API mutation.
        self.lead()
        return self.api.request(method, path, body)

    def node_ok(self, pod):
        node = pod.get("spec", {}).get("nodeName")
        if not node:
            raise Blocked("target has no assigned node")
        obj = self.api.get("/api/v1/nodes/" + node)
        lease = self.api.get("/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/" + node)
        cond = conditions(obj)
        if cond.get("Ready", {}).get("status") != "True" or age(lease.get("spec", {}).get("renewTime")) > 60:
            raise Blocked("node readiness or heartbeat is uncertain")
        if any(cond.get(key, {}).get("status") == "True" for key in ("DiskPressure", "MemoryPressure", "PIDPressure", "NetworkUnavailable")):
            raise Blocked("node pressure or network failure requires infrastructure recovery")

    def cluster(self, policy):
        group = "postgresql.cnpg.io/v1/clusters" if policy["kind"] == "cnpg-preserve-replace" else "k8s.mariadb.com/v1alpha1/mariadbs"
        path = f"/apis/{group.split('/')[0]}/{group.split('/')[1]}/namespaces/{policy['namespace']}/{group.split('/')[2]}/{policy['cluster']}"
        obj = self.api.get(path)
        if obj.get("metadata", {}).get("deletionTimestamp"):
            raise Blocked("cluster is being deleted")
        return path, obj

    def pods(self, policy):
        items = self.api.items(f"/api/v1/namespaces/{policy['namespace']}/pods")
        if policy["kind"] == "cnpg-preserve-replace":
            # Bootstrap/join Job Pods share the cluster label. Only direct Cluster
            # children are database instances; retained completed Jobs are evidence.
            return [x for x in items if x.get("metadata", {}).get("labels", {}).get("cnpg.io/cluster") == policy["cluster"]
                    and any(owner.get("kind") == "Cluster" and owner.get("name") == policy["cluster"]
                            for owner in x.get("metadata", {}).get("ownerReferences", []))]
        return [x for x in items if x.get("metadata", {}).get("labels", {}).get("app.kubernetes.io/instance") == policy["cluster"]
                and x.get("metadata", {}).get("name", "").startswith(policy["cluster"] + "-")]

    def authority(self, policy, cluster, pods, target, allow_missing_target=False):
        expected_count = 2 if allow_missing_target and target not in [pod["metadata"]["name"] for pod in pods] else 3
        if len(pods) != expected_count:
            raise Blocked("initial recovery supports exactly three known members")
        probes = {}
        for pod in pods:
            self.node_ok(pod)
            name = pod["metadata"]["name"]
            if name == target:
                continue
            if pod.get("metadata", {}).get("deletionTimestamp") or conditions(pod).get("Ready", {}).get("status") != "True":
                raise Blocked("a surviving member is not ready")
            probes[name] = self.api.postgres(policy["namespace"], name) if policy["kind"] == "cnpg-preserve-replace" else self.api.galera(policy, pod)
        if policy["kind"] == "cnpg-preserve-replace":
            status = cluster.get("status", {})
            primary = status.get("currentPrimary")
            if not primary or primary == target or status.get("targetPrimary") != primary:
                raise Blocked("primary authority is changing or targets the failed member")
            if status.get("systemID") != policy["expected_identity"]:
                raise Blocked("unexpected PostgreSQL cluster identity")
            primaries = [name for name, row in probes.items() if row.get("replica") is False]
            if primaries != [primary]:
                raise Blocked("SQL primary identity does not agree with native operator")
            if any(row.get("system_id") != policy["expected_identity"] for row in probes.values()):
                raise Blocked("survivor PostgreSQL system identity mismatch")
            if len({row.get("timeline") for row in probes.values()}) != 1:
                raise Blocked("survivor PostgreSQL timelines disagree")
            replica = next(name for name in probes if name != primary)
            rows = [row for row in probes[primary].get("replicas", []) if row.get("name") == replica]
            if len(rows) != 1 or rows[0].get("state") != "streaming" or rows[0].get("lag") is None or not 0 <= float(rows[0]["lag"]) <= 16777216:
                raise Blocked("surviving replica is not streaming within lag policy")
            if "streaming" not in probes[replica].get("receivers", []):
                raise Blocked("surviving replica does not confirm its WAL receiver")
            return primary
        for row in probes.values():
            if row.get("uuid") != policy["expected_identity"] or str(row.get("component", "")).lower() != "primary" or not all(row.get(key) for key in ("synced", "ready", "connected")) or row.get("size", 0) < 2:
                raise Blocked("Galera primary component/quorum/identity is not confirmed")
        if cluster.get("spec", {}).get("galera", {}).get("recovery", {}).get("forceClusterBootstrapInPod"):
            raise Blocked("native Galera forced bootstrap is already in progress")
        return "galera-primary-component"

    def classify(self, policy, pod):
        statuses = pod.get("status", {}).get("containerStatuses", [])
        container = "postgres" if policy["kind"] == "cnpg-preserve-replace" else "mariadb"
        selected = [x for x in statuses if x.get("name") == container]
        if len(selected) != 1 or selected[0].get("restartCount", 0) < 3 or conditions(pod).get("Ready", {}).get("status") == "True":
            return None
        if selected[0].get("state", {}).get("waiting", {}).get("reason") != "CrashLoopBackOff":
            return None
        text = self.api.logs(policy["namespace"], pod["metadata"]["name"], container)
        if policy["kind"] == "cnpg-preserve-replace":
            return "postgres-timeline-divergence" if "requested timeline" in text and "not a child of this server" in text else None
        signatures = ("failed to open gcomm backend connection", "failed to open backend connection", "failed to reach primary view")
        return "galera-transient-join-failure" if any(value in text.lower() for value in signatures) else None

    def fence(self, path, cluster, target, enabled):
        annotations = cluster["metadata"].setdefault("annotations", {})
        values = json.loads(annotations.get(FENCE, "[]"))
        if not isinstance(values, list) or "*" in values:
            raise Blocked("administrator cluster fence is present")
        if enabled and target not in values:
            values.append(target)
        if not enabled:
            values = [value for value in values if value != target]
        annotations[FENCE] = json.dumps(values)
        self.mutate("PUT", path, cluster)

    def tick(self):
        if not self.config["policies"]:
            return result("recovery", "disabled", "no automatic recovery policy configured")
        policy = self.config["policies"][self.index % len(self.config["policies"])]
        self.index += 1
        try:
            return self.step(policy)
        except Blocked as exc:
            return result("recovery/" + policy["name"], "unknown", str(exc))
        except Exception as exc:
            return result("recovery/" + policy["name"], "unknown", "recovery check failed: " + type(exc).__name__)

    def step(self, policy):
        if policy["kind"] == "longhorn-stall-recovery":
            from longhorn_recovery import step
            return step(self, policy)
        if policy["kind"] == "redis-replica-replace":
            from redis_recovery import step
            return step(self, policy)
        self.lead()
        record, all_state = self.load()
        state = all_state.get(policy["name"])
        path, cluster = self.cluster(policy)
        pods = self.pods(policy)
        if state and state["phase"] == "completed":
            if age(state["updated_at"]) < 21600:
                return result("recovery/" + policy["name"], "healthy", "recovery verified; six-hour cooldown", {"operation": state["id"]})
            # Retain prior receipts; cap recoveries instead of silently deleting history.
            history = all_state.setdefault("history", [])
            if len(history) >= 20:
                raise Blocked("recovery receipt capacity reached; export receipts before further recovery")
            history.append(state)
            state = None
        if not state:
            if len(pods) != 3:
                return result("recovery/" + policy["name"], "unknown", "database instance inventory is incomplete; Jobs are not members")
            candidates = [(pod, self.classify(policy, pod)) for pod in pods]
            candidates = [(pod, reason) for pod, reason in candidates if reason]
            if len(candidates) != 1:
                return result("recovery/" + policy["name"], "healthy" if not candidates else "unknown", "no single recognized failed member eligible for automatic action")
            pod, reason = candidates[0]
            target = pod["metadata"]["name"]
            owners = pod["metadata"].get("ownerReferences", [])
            if policy["kind"] == "cnpg-preserve-replace" and not any(owner.get("kind") == "Cluster" and owner.get("uid") == cluster["metadata"]["uid"] for owner in owners):
                raise Blocked("target Pod is not owned by the verified CNPG cluster")
            if policy["kind"] == "galera-rejoin" and not any(owner.get("kind") == "StatefulSet" and owner.get("name") == policy["cluster"] for owner in owners):
                raise Blocked("target Pod is not owned by the expected Galera StatefulSet")
            primary = self.authority(policy, cluster, pods, target)
            if target in json.loads(cluster.get("metadata", {}).get("annotations", {}).get(FENCE, "[]")):
                raise Blocked("target already fenced by another actor")
            pvc_names = [volume["persistentVolumeClaim"]["claimName"] for volume in pod.get("spec", {}).get("volumes", []) if "persistentVolumeClaim" in volume]
            if not pvc_names:
                raise Blocked("database member has no identifiable persistent volumes")
            pvc_uids = {}
            for name in pvc_names:
                pvc = self.api.get(f"/api/v1/namespaces/{policy['namespace']}/persistentvolumeclaims/{name}")
                if pvc.get("metadata", {}).get("deletionTimestamp") or pvc.get("status", {}).get("phase") != "Bound":
                    raise Blocked("database volume is deleting or not bound")
                pvc_uids[name] = pvc["metadata"]["uid"]
            state = {"id": str(uuid.uuid4()), "target": target, "pod_uid": pod["metadata"]["uid"],
                     "cluster_uid": cluster["metadata"]["uid"], "source": primary,
                     "phase": "confirmed", "first_seen": utc(), "updated_at": utc(),
                     "diagnosis": reason, "pvc_names": pvc_names, "pvc_uids": pvc_uids, "preserved": [], "confirmations": 1}
        else:
            target = state["target"]
            if cluster["metadata"]["uid"] != state["cluster_uid"]:
                raise Blocked("cluster was replaced during recovery")
            if age(state["first_seen"]) > 7200:
                raise Blocked("recovery exceeded two-hour action budget; retained data unchanged")
            matching = [pod for pod in pods if pod["metadata"]["name"] == target]
            pod = matching[0] if len(matching) == 1 else None
            # Eviction may have succeeded before a network error or process restart.
            if state["phase"] == "evicting" and (not pod or pod["metadata"]["uid"] != state["pod_uid"]):
                state["phase"] = "waiting"
            if state["phase"] not in ("waiting", "unfencing"):
                if not pod or pod["metadata"]["uid"] != state["pod_uid"]:
                    raise Blocked("target pod identity changed before controlled replacement")
                if conditions(pod).get("Ready", {}).get("status") == "True":
                    raise Blocked("target recovered before replacement; no eviction needed")
                if policy["kind"] == "cnpg-preserve-replace" and state["phase"] in ("preserving", "evicting"):
                    fences = json.loads(cluster.get("metadata", {}).get("annotations", {}).get(FENCE, "[]"))
                    if target not in fences or "*" in fences:
                        raise Blocked("expected native target fence is absent or administrator fence changed")
                primary = self.authority(policy, cluster, pods, target)
                if primary != state["source"]:
                    if state.get("candidate_source") != primary:
                        state.update(candidate_source=primary, source_changed_at=utc(), source_confirmations=0)
                    state["source_confirmations"] += 1
                    if state["source_confirmations"] >= 3 and age(state["source_changed_at"]) >= 120:
                        state["source"] = primary
                        for key in ("candidate_source", "source_changed_at", "source_confirmations"):
                            state.pop(key, None)
                    state["updated_at"] = utc()
                    all_state[policy["name"]] = state
                    self.save(record, all_state)
                    return result("recovery/" + policy["name"], "degraded", "reconfirming native primary after failover")
            if state["phase"] == "confirmed":
                if not self.classify(policy, pod):
                    raise Blocked("failure signature or crash state changed")
                state["confirmations"] += 1
                if state["confirmations"] >= 3 and age(state["first_seen"]) >= 120:
                    state["phase"] = "fencing" if policy["kind"] == "cnpg-preserve-replace" else "evicting"
            elif state["phase"] == "fencing":
                self.fence(path, cluster, target, True)
                state["phase"] = "preserving"
            elif state["phase"] == "preserving":
                for name in state["pvc_names"]:
                    pvc_path = f"/api/v1/namespaces/{policy['namespace']}/persistentvolumeclaims/{name}"
                    pvc = self.api.get(pvc_path)
                    meta = pvc["metadata"]
                    if meta["uid"] != state["pvc_uids"][name]:
                        raise Blocked("PVC identity changed during recovery")
                    annotations = meta.setdefault("annotations", {})
                    if meta.get("deletionTimestamp") or pvc.get("status", {}).get("phase") != "Bound":
                        raise Blocked("source PVC is deleting or not bound")
                    owners = meta.get("ownerReferences", [])
                    owned = any(owner.get("uid") == state["cluster_uid"] and owner.get("kind") == "Cluster" for owner in owners)
                    if not owned and annotations.get(MARK) != state["id"]:
                        raise Blocked("PVC ownership is not this cluster/recovery operation")
                    if annotations.get(MARK) == state["id"] and annotations.get(DETACHED) == "detached" and not owned:
                        if name not in state["preserved"]:
                            state["preserved"].append(name)
                        continue
                    meta["ownerReferences"] = [owner for owner in owners if owner.get("uid") != state["cluster_uid"]]
                    annotations.update({DETACHED: "detached", MARK: state["id"]})
                    meta.setdefault("labels", {})["cnpg.io/instanceName"] = target
                    self.mutate("PUT", pvc_path, pvc)
                    break
                if len(state["preserved"]) == len(state["pvc_names"]):
                    state["phase"] = "evicting"
            elif state["phase"] == "evicting":
                # No force deletion; PDBs and kubelet graceful termination remain enforced.
                eviction = {"apiVersion": "policy/v1", "kind": "Eviction", "metadata": {
                    "name": target, "namespace": policy["namespace"]}, "deleteOptions": {
                    "preconditions": {"uid": state["pod_uid"], "resourceVersion": pod["metadata"]["resourceVersion"]}}}
                self.mutate("POST", f"/api/v1/namespaces/{policy['namespace']}/pods/{target}/eviction", eviction)
                state["phase"] = "waiting"
            elif state["phase"] == "waiting":
                if policy["kind"] == "cnpg-preserve-replace" and (not pod or pod["metadata"]["uid"] != state["pod_uid"]):
                    state["phase"] = "unfencing"
                elif policy["kind"] == "galera-rejoin" and pod and pod["metadata"]["uid"] != state["pod_uid"]:
                    self.verify(policy, cluster, pods)
                    state["phase"] = "completed"
            elif state["phase"] == "unfencing":
                if target in json.loads(cluster.get("metadata", {}).get("annotations", {}).get(FENCE, "[]")):
                    self.fence(path, cluster, target, False)
                handed_back = self.handoff(policy, cluster, pods, state)
                if not handed_back:
                    self.verify(policy, cluster, pods)
                    state["phase"] = "completed"
        state["updated_at"] = utc()
        all_state[policy["name"]] = state
        self.save(record, all_state)
        return result("recovery/" + policy["name"], "healthy" if state["phase"] == "completed" else "degraded",
                      "automatic recovery " + state["phase"], {"operation": state["id"], "target": state["target"], "preserved_pvcs": state["preserved"]})

    def handoff(self, policy, cluster, pods, state):
        """CNPG may reuse the logical instance name/PVC for its join Job.

        Its managed-PVC index uses ownerReferences, not the cluster label. After
        a successful native join, return that PVC to the same controller so CNPG
        can mark it ready and create the real instance. Never forge a ready flag.
        """
        target = state["target"]
        job_path = f"/apis/batch/v1/namespaces/{policy['namespace']}/jobs/{target}-join"
        try:
            job = self.api.get(job_path)
        except Exception as exc:
            if is_404(exc):
                return False
            raise
        owners = job.get("metadata", {}).get("ownerReferences", [])
        if not any(owner.get("kind") == "Cluster" and owner.get("uid") == state["cluster_uid"] for owner in owners):
            raise Blocked("join Job is not owned by the verified native cluster")
        if job.get("status", {}).get("succeeded") != 1 or conditions(job).get("Complete", {}).get("status") != "True":
            raise Blocked("native join Job has not completed successfully")
        if age(job["metadata"].get("creationTimestamp")) > age(state["first_seen"]):
            raise Blocked("join Job predates this recovery operation")
        claims = {volume["persistentVolumeClaim"]["claimName"] for volume in job.get("spec", {}).get("template", {}).get("spec", {}).get("volumes", []) if "persistentVolumeClaim" in volume}
        relevant = [name for name in state["pvc_names"] if name in claims]
        if not relevant:
            return False
        source = self.authority(policy, cluster, pods, target, allow_missing_target=True)
        if source != state["source"]:
            raise Blocked("native source changed before retained-volume hand-off")
        for name in relevant:
            pvc_path = f"/api/v1/namespaces/{policy['namespace']}/persistentvolumeclaims/{name}"
            pvc = self.api.get(pvc_path)
            meta = pvc["metadata"]
            if meta.get("uid") != state["pvc_uids"][name] or meta.get("deletionTimestamp"):
                raise Blocked("retained PVC identity changed before hand-off")
            annotations = meta.get("annotations", {})
            if annotations.get(MARK) != state["id"]:
                raise Blocked("retained PVC does not belong to this recovery operation")
            owners = meta.get("ownerReferences", [])
            if any(owner.get("kind") == "Cluster" and owner.get("uid") == state["cluster_uid"] for owner in owners):
                continue
            if owners or annotations.get(DETACHED) != "detached":
                raise Blocked("retained PVC has an unexpected controller or state")
            join_pods = [pod for pod in self.api.items(f"/api/v1/namespaces/{policy['namespace']}/pods")
                if any(owner.get("kind") == "Job" and owner.get("uid") == job["metadata"]["uid"] for owner in pod["metadata"].get("ownerReferences", []))
                and pod.get("status", {}).get("phase") == "Succeeded"]
            if len(join_pods) != 1:
                raise Blocked("completed native join Pod evidence is unavailable")
            self.node_ok(join_pods[0])
            text = self.api.logs(policy["namespace"], join_pods[0]["metadata"]["name"], "join", previous=False)
            archives = []
            backup_done = False
            for line in text.splitlines():
                try:
                    row = json.loads(line)
                except (ValueError, TypeError):
                    continue
                if row.get("msg") == "renaming the data directory" and row.get("pgdataNewName"):
                    archives.append(row["pgdataNewName"])
                if row.get("logger") == "pg_basebackup" and "base backup completed" in row.get("msg", ""):
                    backup_done = True
            if not archives or not backup_done:
                raise Blocked("native logs do not confirm old-directory retention and completed base backup")
            meta["ownerReferences"] = [{"apiVersion": "postgresql.cnpg.io/v1", "kind": "Cluster",
                "name": policy["cluster"], "uid": state["cluster_uid"], "controller": True}]
            self.mutate("PUT", pvc_path, pvc)
            state["archived_data_paths"] = archives
            state["preservation_mode"] = "same-volume archive; not an independent backup"
            state.setdefault("restored_pvc_ownership", []).append(name)
            return True
        return False

    def verify(self, policy, cluster, pods):
        if len(pods) != 3 or any(conditions(pod).get("Ready", {}).get("status") != "True" for pod in pods):
            raise Blocked("native operator replacement is not ready yet")
        # Probe every member; primary plus two replicas must agree before completion.
        for target in (pod["metadata"]["name"] for pod in pods):
            self.authority(policy, cluster, pods, target) if policy["kind"] == "galera-rejoin" else None
        if policy["kind"] == "cnpg-preserve-replace":
            primary = cluster.get("status", {}).get("currentPrimary")
            for target in (pod["metadata"]["name"] for pod in pods if pod["metadata"]["name"] != primary):
                self.authority(policy, cluster, pods, target)
