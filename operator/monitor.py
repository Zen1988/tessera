"""TESSERA infrastructure observer. No mutation, shell execution, DB or PVC."""
import argparse
import datetime as dt
import http.server
import json
import multiprocessing as mp
import os
from pathlib import Path, PurePosixPath
import queue
import signal
import socket
import ssl
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

VERSION = "0.3.3"
SA = Path("/var/run/secrets/kubernetes.io/serviceaccount")
STATES = {"healthy": 0, "disabled": 0, "degraded": 1, "unknown": 2, "unavailable": 3}
MAX_BODY = 8 * 1024 * 1024


def utc():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def age(value):
    try:
        return max(0, (dt.datetime.now(dt.timezone.utc) -
                       dt.datetime.fromisoformat(value.replace("Z", "+00:00"))).total_seconds())
    except (ValueError, TypeError, AttributeError):
        return float("inf")


def result(name, state, reason, details=None):
    return {"name": name, "state": state, "reason": reason,
            "observed_at": utc(), "details": details or {}}


def aggregate(name, checks, reason="observations collected"):
    state = max((c["state"] for c in checks), key=lambda s: STATES[s], default="unknown")
    return result(name, state, reason, {"checks": checks})


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def get_json(url, token=None, ca=None, timeout=4):
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        raise ValueError("HTTPS endpoint without embedded credentials required")
    context = ssl.create_default_context(cafile=ca)
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}),
        urllib.request.HTTPSHandler(context=context), NoRedirect())
    headers = {"Accept": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    with opener.open(urllib.request.Request(url, headers=headers), timeout=timeout) as response:
        body = response.read(MAX_BODY + 1)
        if len(body) > MAX_BODY:
            raise ValueError("response exceeds limit")
        return json.loads(body)


class Kube:
    def __init__(self):
        host = os.environ.get("KUBERNETES_SERVICE_HOST", "kubernetes.default.svc")
        if ":" in host and not host.startswith("["):
            host = "[" + host + "]"
        port = os.environ.get("KUBERNETES_SERVICE_PORT_HTTPS", "443")
        self.base = "https://" + host + ":" + port
        import ipaddress
        configured = os.environ.get("TESSERA_API_ENDPOINTS", "")
        endpoints = [self.base]
        for endpoint in configured.split(",") if configured else []:
            parsed = urllib.parse.urlsplit(endpoint)
            if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password or parsed.path or parsed.query or parsed.fragment:
                raise ValueError("explicit HTTPS API origins required")
            ipaddress.ip_address(parsed.hostname)  # Restrict fallbacks to configured literal addresses.
            if parsed.port != 6443:
                raise ValueError("direct API endpoint must use port 6443")
            if endpoint not in endpoints:
                endpoints.append(endpoint)
        if len(endpoints) > 4:
            raise ValueError("at most three direct API fallbacks supported")
        self.endpoints = endpoints

    def get(self, path):
        # Read projected credentials on every request so token rotation is honored.
        token = (SA / "token").read_text().strip()
        last = None
        endpoints = getattr(self, "endpoints", [self.base])
        ordered = [self.base] + [endpoint for endpoint in endpoints if endpoint != self.base]
        for endpoint in ordered:
            try:
                value = get_json(endpoint + path, token, str(SA / "ca.crt"), timeout=2)
                self.base = endpoint
                return value
            except urllib.error.HTTPError as exc:
                if exc.code not in (500, 502, 503, 504):
                    raise  # Never mask RBAC, authentication, conflicts or missing resources.
                last = exc
            except (urllib.error.URLError, TimeoutError, ConnectionError) as exc:
                last = exc
        raise last

    def items(self, path):
        items, continuation = [], None
        for _ in range(20):
            args = {"limit": 200}
            if continuation:
                args["continue"] = continuation
            page = self.get(path + "?" + urllib.parse.urlencode(args))
            items.extend(page.get("items", []))
            continuation = page.get("metadata", {}).get("continue")
            if not continuation:
                return items
        raise ValueError("resource inventory exceeds bounded pagination limit")


def conditions(obj):
    values = obj.get("status", {}).get("conditions", [])
    if isinstance(values, dict):
        values = values.values()
    return {x.get("type"): x for x in values if isinstance(x, dict)}


def resource_name(obj):
    meta = obj.get("metadata", {})
    return "/".join(filter(None, [meta.get("namespace"), meta.get("name", "unknown")]))


def node_check(obj, lease=None):
    cond = conditions(obj)
    ready = cond.get("Ready", {}).get("status")
    problems = [key for key in ("MemoryPressure", "DiskPressure", "PIDPressure", "NetworkUnavailable")
                if cond.get(key, {}).get("status") == "True"]
    heartbeat_age = age((lease or {}).get("spec", {}).get("renewTime"))
    state = "healthy"
    if ready == "False":
        state = "unavailable"
    elif ready != "True" or heartbeat_age > 90:
        state = "unknown"
    elif problems:
        state = "degraded"
    return result(resource_name(obj), state, "node readiness, pressure and lease",
        {"ready": ready, "pressure": problems, "lease_fresh": heartbeat_age <= 90,
         "unschedulable": bool(obj.get("spec", {}).get("unschedulable")),
         "note": "unreachable does not establish that a database writer stopped"})


def pod_check(obj, grace=180):
    status = obj.get("status", {})
    phase = status.get("phase", "Unknown")
    cond = conditions(obj)
    meta = obj.get("metadata", {})
    deletion_age = age(meta.get("deletionTimestamp"))
    ready = cond.get("Ready", {}).get("status") == "True"
    reason = phase
    state = "healthy"
    if meta.get("deletionTimestamp"):
        state = "degraded" if deletion_age > grace else "unknown"
        reason = "termination overdue" if deletion_age > grace else "terminating"
    elif phase == "Failed":
        state = "unavailable"
    elif phase == "Succeeded":
        reason = "completed"
    elif phase != "Running" or not ready:
        state = "degraded" if age(meta.get("creationTimestamp")) > grace else "unknown"
        reason = "not ready"
    containers = status.get("containerStatuses", []) + status.get("initContainerStatuses", [])
    waiting = [x.get("state", {}).get("waiting", {}).get("reason") for x in containers]
    waiting = [x for x in waiting if x]
    return result(resource_name(obj), state, reason, {"node": obj.get("spec", {}).get("nodeName"),
        "phase": phase, "ready": ready, "waiting": waiting,
        "restarts": sum(x.get("restartCount", 0) for x in containers)})


def pvc_check(obj):
    phase = obj.get("status", {}).get("phase", "Unknown")
    cond = conditions(obj)
    pending = [key for key, value in cond.items() if value.get("status") == "True"
               and not (key == "Unused" and value.get("reason") == "NoPodsUsingPVC")]
    state = "healthy" if phase == "Bound" and not pending else "degraded"
    return result(resource_name(obj), state, "PVC binding only; application I/O not verified",
         {"phase": phase, "conditions": pending, "volume": obj.get("spec", {}).get("volumeName")})


def workload_check(obj, kind=None):
    spec, status = obj.get("spec", {}), obj.get("status", {})
    kind = kind or obj.get("kind")
    desired = status.get("desiredNumberScheduled") if kind == "DaemonSet" else spec.get("replicas", 1)
    ready = status.get("numberReady", 0) if kind == "DaemonSet" else status.get("readyReplicas", 0)
    fresh = status.get("observedGeneration", -1) >= obj.get("metadata", {}).get("generation", 0)
    state = "healthy" if desired is not None and ready >= desired and fresh else "degraded"
    return result(resource_name(obj), state, "workload replica observation",
                  {"desired": desired, "ready": ready, "generation_observed": fresh})


def protected(name, fn):
    try:
        return fn()
    except urllib.error.HTTPError as exc:
        return result(name, "unknown", "API HTTP " + str(exc.code))
    except Exception as exc:
        # Exception messages may contain credentials, DSNs or server-controlled text.
        return result(name, "unknown", "check failed: " + type(exc).__name__)


def inventory(kube, name, path, evaluator, allow_empty=False):
    def run():
        objects = kube.items(path)
        if not objects:
            if allow_empty:
                return result(name, "healthy", "inventory readable; no resources present", {"count": 0})
            return result(name, "unknown", "no resources found; verify scope and installation")
        return aggregate(name, [evaluator(obj) for obj in objects])
    return protected(name, run)


def infrastructure(config):
    kube = Kube()
    checks = []
    checks.append(protected("observer/api", lambda: result("observer/api", "healthy",
        "authenticated API reachable", {"version": kube.get("/version").get("gitVersion")})))
    def dns():
        socket.getaddrinfo("kubernetes.default.svc", 443)
        return result("observer/dns", "healthy", "cluster API DNS resolved; other paths unproven")
    checks.append(protected("observer/dns", dns))
    def nodes():
        leases = {x["metadata"]["name"]: x for x in kube.items(
            "/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases")}
        return inventory(kube, "nodes", "/api/v1/nodes",
                         lambda obj: node_check(obj, leases.get(obj["metadata"]["name"])))
    checks.append(protected("nodes", nodes))
    for namespace in config["namespaces"]:
        root = "/api/v1/namespaces/" + namespace
        checks.append(inventory(kube, namespace + "/pods", root + "/pods", pod_check))
        checks.append(inventory(kube, namespace + "/pvcs", root + "/persistentvolumeclaims", pvc_check, allow_empty=True))
    checks.append(inventory(kube, "volume-attachments", "/apis/storage.k8s.io/v1/volumeattachments",
        lambda obj: result(resource_name(obj),
            "degraded" if obj.get("status", {}).get("attachError") or obj.get("status", {}).get("detachError") else "healthy" if obj.get("status", {}).get("attached") else "unknown",
            "attachment observation; detached may be intentional", {"attached": obj.get("status", {}).get("attached")}), allow_empty=True))
    return aggregate("kubernetes", checks)


def metrics(config):
    kube = Kube()
    def observe(obj):
        if age(obj.get("timestamp")) > 120:
            return result(resource_name(obj), "unknown", "resource metrics missing or stale")
        data = {"timestamp": obj.get("timestamp"), "window": obj.get("window")}
        if "usage" in obj:
            data["usage"] = obj["usage"]
        else:
            data["containers"] = [{"name": x.get("name"), "usage": x.get("usage")}
                                  for x in obj.get("containers", [])]
        return result(resource_name(obj), "healthy", "resource usage in Kubernetes quantity units; no scaling action", data)
    checks = [inventory(kube, "metrics/nodes", "/apis/metrics.k8s.io/v1beta1/nodes", observe)]
    for namespace in config["namespaces"]:
        checks.append(inventory(kube, "metrics/" + namespace,
            "/apis/metrics.k8s.io/v1beta1/namespaces/" + namespace + "/pods", observe))
    return aggregate("metrics", checks)


def longhorn(config):
    kube = Kube()
    ns = config.get("longhorn_namespace", "longhorn-system")
    root = "/apis/longhorn.io/v1beta2/namespaces/" + ns
    def volume(obj):
        status = obj.get("status", {})
        robustness = status.get("robustness", "unknown")
        state = "healthy" if robustness == "healthy" else "degraded" if robustness in ("degraded", "faulted") else "unknown"
        reason = "detached volume; runtime robustness unverified" if status.get("state") == "detached" and robustness == "unknown" else "Longhorn volume robustness"
        return result(resource_name(obj), state, reason,
                      {"robustness": robustness, "state": status.get("state")})
    def node(obj):
        cond = conditions(obj)
        ready = cond.get("Ready", {}).get("status")
        return result(resource_name(obj), "healthy" if ready == "True" else "degraded",
                      "Longhorn node readiness", {"ready": ready})
    return aggregate("longhorn", [inventory(kube, "longhorn/volumes", root + "/volumes", volume),
        inventory(kube, "longhorn/nodes", root + "/nodes", node),
        inventory(kube, "longhorn/pods", "/api/v1/namespaces/" + ns + "/pods", pod_check)])


def metallb(config):
    kube = Kube()
    ns = config.get("metallb_namespace", "metallb-system")
    checks = []
    for kind in ("deployments", "daemonsets"):
        checks.append(inventory(kube, "metallb/" + kind,
            "/apis/apps/v1/namespaces/" + ns + "/" + kind,
            lambda obj, resource=kind: workload_check(obj, "DaemonSet" if resource == "daemonsets" else "Deployment")))
    root = "/apis/metallb.io/v1beta1/namespaces/" + ns
    checks.append(protected("metallb/config", lambda: result("metallb/config", "unknown",
        "configuration observed; L2/BGP advertisement not verified",
        {"pools": len(kube.items(root + "/ipaddresspools")),
         "l2_advertisements": len(kube.items(root + "/l2advertisements"))})))
    def services():
        objects = []
        for namespace in config["namespaces"]:
            objects.extend(kube.items("/api/v1/namespaces/" + namespace + "/services"))
        targets = [x for x in objects if x.get("spec", {}).get("type") == "LoadBalancer"]
        if not targets:
            return result("loadbalancer/services", "unknown", "no LoadBalancer services in monitored namespaces")
        return aggregate("loadbalancer/services", [result(resource_name(x),
            "unknown" if x.get("status", {}).get("loadBalancer", {}).get("ingress") else "degraded",
            "address allocated; reachability and controller ownership unverified" if x.get("status", {}).get("loadBalancer", {}).get("ingress") else "no address allocated") for x in targets])
    checks.append(protected("loadbalancer/services", services))
    return aggregate("metallb", checks)


def secret_file(target, key):
    path = target.get(key)
    return Path(path).read_text().rstrip("\r\n") if path else None


def mariadb(target):
    import pymysql
    conn = pymysql.connect(host=target["host"], port=target.get("port", 3306),
        user=target["user"], password=secret_file(target, "password_file"),
        ssl_ca=target["ca_file"], ssl_verify_cert=True, ssl_verify_identity=True,
        connect_timeout=3, read_timeout=3, write_timeout=3)
    try:
        with conn.cursor() as cur:
            cur.execute("SHOW GLOBAL STATUS LIKE 'wsrep_%'")
            values = dict(cur.fetchall())
        keys = ("wsrep_cluster_status", "wsrep_ready", "wsrep_connected",
                "wsrep_local_state_comment", "wsrep_cluster_size", "wsrep_cluster_state_uuid")
        data = {key: values.get(key) for key in keys}
        if any(value is None for value in data.values()):
            return result(target["name"], "unknown", "Galera status incomplete", data)
        match = values["wsrep_cluster_state_uuid"] == target["expected_cluster_uuid"]
        healthy = (match and values["wsrep_cluster_status"].lower() == "primary" and
            values["wsrep_ready"] == "ON" and values["wsrep_connected"] == "ON" and
            values["wsrep_local_state_comment"] == "Synced" and
            int(values["wsrep_cluster_size"]) >= target["minimum_members"])
        data["expected_identity_matches"] = match
        return result(target["name"], "healthy" if healthy else "degraded",
                      "Galera member observation; no recovery authority inferred", data)
    finally:
        conn.close()


def redis_check(target):
    import redis
    client = redis.Redis(host=target["host"], port=target.get("port", 6379),
        username=target.get("user"), password=secret_file(target, "password_file"),
        ssl=True, ssl_ca_certs=target["ca_file"], ssl_check_hostname=True,
        socket_connect_timeout=3, socket_timeout=3, decode_responses=True, protocol=2)
    try:
        replication = client.info("replication")
        persistence = client.info("persistence")
        role = replication.get("role")
        data = {"role": role, "master_link_status": replication.get("master_link_status"),
                "connected_slaves": replication.get("connected_slaves"),
                "rdb_last_bgsave_status": persistence.get("rdb_last_bgsave_status"),
                "aof_last_write_status": persistence.get("aof_last_write_status")}
        if "loading" not in persistence or "rdb_last_bgsave_status" not in persistence:
            return result(target["name"], "unknown", "Redis persistence information incomplete", data)
        good = role == target["expected_role"]
        good = good and not persistence.get("loading")
        if role == "slave":
            good = good and replication.get("master_link_status") == "up" and (
                replication.get("master_host") == target["expected_primary_host"])
        elif role == "master":
            good = good and replication.get("connected_slaves", 0) >= target["minimum_replicas"]
        else:
            good = False
        for key in ("rdb_last_bgsave_status", "aof_last_write_status"):
            if persistence.get(key) == "err":
                good = False
        return result(target["name"], "healthy" if good else "degraded",
            "Redis replication/persistence observation; Sentinel agreement not established", data)
    finally:
        client.close()


def sentinel_check(target):
    import redis
    client = redis.Redis(host=target["host"], port=target.get("port", 26379),
        username=target.get("user"), password=secret_file(target, "password_file"),
        ssl=True, ssl_ca_certs=target["ca_file"], ssl_check_hostname=True,
        socket_connect_timeout=3, socket_timeout=3, decode_responses=True, protocol=2)
    try:
        value = client.sentinel_master(target["master_name"])
        quorum = client.execute_command("SENTINEL", "CKQUORUM", target["master_name"])
        good = (str(value.get("ip")) == target["expected_primary_host"] and
                str(value.get("port")) == str(target["expected_primary_port"]) and
                not value.get("is_sdown") and not value.get("is_odown") and str(quorum).startswith("OK"))
        return result(target["name"], "healthy" if good else "degraded",
            "single Sentinel view; compare independent Sentinels before recovery",
            {"primary_host": value.get("ip"), "primary_port": value.get("port"),
             "quorum_check_passed": str(quorum).startswith("OK")})
    finally:
        client.close()


def postgres(target):
    import psycopg
    with psycopg.connect(host=target["host"], port=target.get("port", 5432),
        user=target["user"], password=secret_file(target, "password_file"),
        dbname=target.get("database", "postgres"), connect_timeout=3,
        sslmode="verify-full", sslrootcert=target["ca_file"],
        options="-c statement_timeout=3000 -c default_transaction_read_only=on") as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT pg_is_in_recovery(), current_setting('cluster_name')")
            recovery, cluster = cur.fetchone()
            cur.execute("SELECT system_identifier::text FROM pg_control_system()")
            identity = cur.fetchone()[0]
            cur.execute("SELECT status FROM pg_stat_wal_receiver")
            receivers = [row[0] for row in cur.fetchall()]
        role = "replica" if recovery else "primary"
        good = role == target["expected_role"] and identity == target["expected_system_identifier"]
        if recovery:
            good = good and "streaming" in receivers
        return result(target["name"], "healthy" if good else "degraded",
            "PostgreSQL member observation; topology-manager authority not established",
            {"role": role, "cluster_name": cluster, "system_identifier": identity,
             "wal_receiver_streaming": "streaming" in receivers})


def awx(target):
    data = get_json(target["url"].rstrip("/") + "/api/v2/ping/",
                    secret_file(target, "token_file"), target.get("ca_file"))
    instances = data.get("instances")
    # HTTP success alone is not full job-execution health.
    return result(target["name"], "unknown", "AWX API responds; job execution and dependencies unverified",
                  {"version": data.get("version"),
                   "reported_instances": len(instances) if isinstance(instances, list) else None})


ADAPTERS = {"mariadb": mariadb, "redis": redis_check, "sentinel": sentinel_check,
            "postgresql": postgres, "awx": awx}


def worker(kind, config, output):
    functions = {"kubernetes": infrastructure, "longhorn": longhorn, "metallb": metallb, "metrics": metrics, **ADAPTERS}
    output.put(protected(config.get("name", kind), lambda: functions[kind](config)))


def run_checks(config, stop=None):
    tasks = [(kind, config) for kind in ("kubernetes", "longhorn", "metallb", "metrics")]
    tasks.extend((target["kind"], target) for target in config["targets"])
    # Spawned processes provide a hard wall-clock limit, including DNS and driver hangs.
    context = mp.get_context("spawn")
    active, completed = [], []
    deadline = config["check_deadline_seconds"]
    try:
        while tasks or active:
            if stop and stop.is_set():
                break
            while tasks and len(active) < config["max_workers"]:
                kind, target = tasks.pop(0)
                output = context.Queue(maxsize=1)
                proc = context.Process(target=worker, args=(kind, target, output), daemon=True)
                proc.start()
                active.append((proc, output, time.monotonic(), target.get("name", kind)))
            for item in list(active):
                proc, output, started, name = item
                try:
                    value = output.get_nowait()
                except queue.Empty:
                    if proc.is_alive() and time.monotonic() - started < deadline:
                        continue
                    value = result(name, "unknown", "check deadline exceeded" if proc.is_alive() else "check process failed")
                completed.append(value)
                if proc.is_alive():
                    proc.terminate()
                proc.join(timeout=1)
                if proc.is_alive():
                    proc.kill()
                    proc.join(timeout=1)
                output.close()
                active.remove(item)
            if active:
                time.sleep(0.05)
    finally:
        for proc, output, _, _ in active:
            if proc.is_alive():
                proc.kill()
            proc.join(timeout=1)
            output.close()
    configured = {target["kind"] for target in config["targets"]}
    for kind in ADAPTERS:
        if kind not in configured:
            completed.append(result(kind, "unknown", "no endpoints configured; protocol health not assessed"))
    return sorted(completed, key=lambda item: item["name"])


def validate(config):
    import re
    allowed = {"namespaces", "longhorn_namespace", "metallb_namespace", "targets",
               "interval_seconds", "check_deadline_seconds", "max_workers"}
    if set(config) - allowed:
        raise ValueError("unknown configuration key")
    config = {"namespaces": ["apps"], "targets": [], "interval_seconds": 60,
              "check_deadline_seconds": 45, "max_workers": 4, **config}
    for key, low, high in (("interval_seconds", 10, 3600), ("check_deadline_seconds", 5, 120), ("max_workers", 1, 8)):
        if type(config[key]) is not int or not low <= config[key] <= high:
            raise ValueError("invalid " + key)
    namespaces = config["namespaces"]
    if not isinstance(namespaces, list) or not 1 <= len(namespaces) <= 32:
        raise ValueError("namespaces must contain 1..32 names")
    for namespace in namespaces + [config.get("longhorn_namespace", "longhorn-system"), config.get("metallb_namespace", "metallb-system")]:
        if not isinstance(namespace, str) or len(namespace) > 63 or not re.fullmatch(r"[a-z0-9](?:[a-z0-9-]*[a-z0-9])?", namespace):
            raise ValueError("invalid namespace")
    if not isinstance(config["targets"], list) or len(config["targets"]) > 64:
        raise ValueError("too many targets")
    names = set()
    common = {"kind", "name", "host", "port", "user", "password_file", "ca_file"}
    extras = {"mariadb": {"expected_cluster_uuid", "minimum_members"},
              "redis": {"expected_role", "expected_primary_host", "minimum_replicas"},
              "sentinel": {"master_name", "expected_primary_host", "expected_primary_port"},
              "postgresql": {"expected_role", "expected_system_identifier", "database"},
              "awx": {"url", "token_file"}}
    for target in config["targets"]:
        kind = target.get("kind")
        if kind not in ADAPTERS or set(target) - (common | extras[kind]):
            raise ValueError("invalid target kind or field")
        name = target.get("name")
        if not isinstance(name, str) or not re.fullmatch(r"[a-zA-Z0-9/_.-]{1,100}", name) or name in names or name in {"kubernetes", "longhorn", "metallb"}:
            raise ValueError("invalid or duplicate target name")
        names.add(name)
        required = {"host", "ca_file"} if kind != "awx" else {"url"}
        if kind in ("mariadb", "postgresql"):
            required |= {"user", "password_file"}
        if kind == "mariadb":
            required |= {"expected_cluster_uuid", "minimum_members"}
        if kind in ("redis", "postgresql"):
            required |= {"expected_role"}
        if kind == "postgresql":
            required |= {"expected_system_identifier"}
        if kind == "sentinel":
            required |= extras[kind]
        if kind == "redis":
            if target.get("expected_role") not in ("master", "slave"):
                raise ValueError("Redis expected_role must be master or slave")
            required |= {"expected_primary_host"} if target["expected_role"] == "slave" else {"minimum_replicas"}
        if kind == "postgresql" and target.get("expected_role") not in ("primary", "replica"):
            raise ValueError("invalid PostgreSQL role")
        if any(key not in target or target[key] is None or target[key] == "" for key in required):
            raise ValueError("missing target identity or connection configuration")
        for key in ("minimum_members", "minimum_replicas", "port", "expected_primary_port"):
            if key in target and (type(target[key]) is not int or not (0 if key == "minimum_replicas" else 1) <= target[key] <= 65535):
                raise ValueError("invalid " + key)
        for key in ("password_file", "ca_file", "token_file"):
            if key in target and not PurePosixPath(target[key]).is_absolute():
                raise ValueError("credential and CA paths must be absolute")
        if kind == "awx":
            parsed = urllib.parse.urlsplit(target["url"])
            if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
                raise ValueError("invalid AWX HTTPS URL")
    return config


class Snapshot:
    def __init__(self, config):
        self.lock = threading.Lock()
        self.config = config
        self.data = {"version": VERSION, "mode": "observe-only", "state": "unknown", "checks": []}
        self.finished = 0
        self.progress = time.monotonic()

    def publish(self, checks):
        with self.lock:
            self.finished = self.progress = time.monotonic()
            self.data = {"version": VERSION, "mode": "observe-only", "observed_at": utc(),
                "state": max((x["state"] for x in checks), key=lambda s: STATES[s], default="unknown"), "checks": checks}

    def read(self):
        with self.lock:
            fresh = bool(self.finished) and time.monotonic() - self.finished < self.stale_limit()
            return {**self.data, "fresh": fresh, "state": self.data["state"] if fresh else "unknown"}

    def stale_limit(self):
        batches = (4 + len(self.config["targets"]) + self.config["max_workers"] - 1) // self.config["max_workers"]
        return self.config["interval_seconds"] + batches * (self.config["check_deadline_seconds"] + 3) + 30


def handler(snapshot):
    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path == "/livez":
                code = 200 if time.monotonic() - snapshot.progress < snapshot.stale_limit() else 503
                value = {"live": code == 200}
            elif self.path == "/readyz":
                # Readiness reflects the observer loop, not dependencies being healthy.
                code = 200 if snapshot.read()["fresh"] else 503
                value = {"ready": code == 200}
            elif self.path == "/status":
                code, value = 200, snapshot.read()
            else:
                code, value = 404, {"error": "not found"}
            body = json.dumps(value, allow_nan=False).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass
    return Handler


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default="/etc/tessera-operator/config.json")
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--recovery-config", help="explicit opt-in policy file for automatic recovery")
    args = parser.parse_args()
    try:
        config = validate(json.loads(Path(args.config).read_text()))
    except Exception as exc:
        print(json.dumps({"error": "invalid configuration", "type": type(exc).__name__}), flush=True)
        return 2
    if args.validate:
        if args.recovery_config:
            from recovery import validate as validate_recovery
            validate_recovery(json.loads(Path(args.recovery_config).read_text()))
        print("configuration valid")
        return 0
    recovery = None
    if args.recovery_config:
        from recovery import Controller
        recovery = Controller(json.loads(Path(args.recovery_config).read_text()))
    if args.once:
        print(json.dumps({"version": VERSION, "checks": run_checks(config)}), flush=True)
        return 0
    stop = threading.Event()
    for sig in (signal.SIGINT, signal.SIGTERM):
        signal.signal(sig, lambda *_: stop.set())
    snapshot = Snapshot(config)
    server = http.server.ThreadingHTTPServer(("0.0.0.0", 8080), handler(snapshot))
    server.daemon_threads = True
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        while not stop.is_set():
            checks = run_checks(config, stop)
            if recovery and not stop.is_set():
                checks.append(recovery.tick())
            snapshot.publish(checks)
            if recovery:
                with snapshot.lock:
                    snapshot.data["mode"] = "automatic-recovery"
            print(json.dumps(snapshot.read(), allow_nan=False), flush=True)
            stop.wait(config["interval_seconds"])
    finally:
        server.shutdown()
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
