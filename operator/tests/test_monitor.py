import datetime as dt
import io
import json
import multiprocessing as mp
from pathlib import Path
import sys
import threading
import time
import types
import unittest
from unittest.mock import MagicMock, patch
import urllib.error
import urllib.request

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import monitor as m


def stamp(seconds=0):
    return (dt.datetime.now(dt.timezone.utc) - dt.timedelta(seconds=seconds)).isoformat()


class ConfigTests(unittest.TestCase):
    def test_example_valid(self):
        data = json.loads((Path(__file__).resolve().parents[1] / "config.example.json").read_text())
        self.assertEqual(len(m.validate(data)["targets"]), 5)

    def test_unknown_key_rejected(self):
        with self.assertRaises(ValueError):
            m.validate({"allow_restart": True})

    def test_bad_namespace_rejected(self):
        for value in ("apps/../../secrets", "", "*", "Apps"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                m.validate({"namespaces": [value]})

    def test_unbounded_workers_rejected(self):
        for value in (0, 100, True):
            with self.assertRaises(ValueError):
                m.validate({"max_workers": value})

    def test_missing_identity_rejected(self):
        with self.assertRaises(ValueError):
            m.validate({"targets": [{"kind": "mariadb", "name": "db", "host": "db", "ca_file": "/ca"}]})

    def test_duplicate_names_rejected(self):
        target = {"kind": "awx", "name": "awx/api", "url": "https://awx"}
        with self.assertRaises(ValueError):
            m.validate({"targets": [target, target]})

    def test_plaintext_and_url_credentials_rejected(self):
        for url in ("http://awx", "https://user:password@awx", "https://awx?token=secret"):
            with self.assertRaises(ValueError):
                m.validate({"targets": [{"kind": "awx", "name": "awx", "url": url}]})


class ObservationTests(unittest.TestCase):
    def node(self):
        return {"metadata": {"name": "node1"}, "status": {"conditions": [{"type": "Ready", "status": "True"}]}}

    def test_ready_node_stale_lease_is_unknown(self):
        value = m.node_check(self.node(), {"spec": {"renewTime": stamp(300)}})
        self.assertEqual(value["state"], "unknown")

    def test_ready_node_fresh_lease_is_healthy(self):
        self.assertEqual(m.node_check(self.node(), {"spec": {"renewTime": stamp()}})["state"], "healthy")

    def test_node_pressure_is_degraded(self):
        node = self.node()
        node["status"]["conditions"].append({"type": "DiskPressure", "status": "True"})
        self.assertEqual(m.node_check(node, {"spec": {"renewTime": stamp()}})["state"], "degraded")

    def test_terminating_pod_overdue(self):
        obj = {"metadata": {"name": "redis", "deletionTimestamp": stamp(400)}, "status": {"phase": "Running"}}
        self.assertEqual(m.pod_check(obj)["reason"], "termination overdue")

    def test_completed_job_is_healthy(self):
        self.assertEqual(m.pod_check({"status": {"phase": "Succeeded"}})["state"], "healthy")

    def test_bound_pvc_does_not_claim_io(self):
        value = m.pvc_check({"status": {"phase": "Bound"}})
        self.assertEqual(value["state"], "healthy")
        self.assertIn("I/O not verified", value["reason"])

    def test_pvc_resize_condition_degraded(self):
        obj = {"status": {"phase": "Bound", "conditions": [{"type": "FileSystemResizePending", "status": "True"}]}}
        self.assertEqual(m.pvc_check(obj)["state"], "degraded")

    def test_workload_old_generation_degraded(self):
        obj = {"metadata": {"generation": 3}, "spec": {"replicas": 2}, "status": {"readyReplicas": 2, "observedGeneration": 2}}
        self.assertEqual(m.workload_check(obj)["state"], "degraded")

    def test_secret_exception_is_redacted(self):
        def fail():
            raise RuntimeError("password=DO_NOT_PRINT")
        value = m.protected("db", fail)
        self.assertNotIn("DO_NOT_PRINT", json.dumps(value))
        self.assertEqual(value["state"], "unknown")

    def test_forbidden_is_unknown(self):
        def fail():
            raise urllib.error.HTTPError("https://api", 403, "secret", {}, None)
        self.assertEqual(m.protected("api", fail)["reason"], "API HTTP 403")

    def test_empty_inventory_not_healthy(self):
        kube = MagicMock()
        kube.items.return_value = []
        self.assertEqual(m.inventory(kube, "pods", "/pods", m.pod_check)["state"], "unknown")

    def test_paginated_inventory(self):
        kube = m.Kube()
        with patch.object(kube, "get", side_effect=[{"items": [1], "metadata": {"continue": "token /?"}}, {"items": [2]}]) as get:
            self.assertEqual(kube.items("/pods"), [1, 2])
            self.assertIn("continue=token+%2F%3F", get.call_args.args[0])

    def test_redirect_not_followed(self):
        self.assertIsNone(m.NoRedirect().redirect_request(None, None, 302, "", {}, "https://attacker"))

    def test_http_transport_rejects_plaintext(self):
        with self.assertRaises(ValueError):
            m.get_json("http://api", token="secret")


class ProtocolTests(unittest.TestCase):
    def target(self, kind):
        return {"kind": kind, "name": "member", "host": "member", "user": "monitor", "ca_file": "/ca",
                "expected_cluster_uuid": "trusted", "minimum_members": 3,
                "expected_role": "master", "minimum_replicas": 2}

    def test_galera_wrong_cluster_degraded_and_no_mutation(self):
        conn, module = MagicMock(), MagicMock()
        module.connect.return_value = conn
        cursor = conn.cursor.return_value.__enter__.return_value
        cursor.fetchall.return_value = [("wsrep_cluster_status", "Primary"), ("wsrep_ready", "ON"),
            ("wsrep_connected", "ON"), ("wsrep_local_state_comment", "Synced"),
            ("wsrep_cluster_size", "3"), ("wsrep_cluster_state_uuid", "other")]
        with patch.dict(sys.modules, {"pymysql": module}):
            self.assertEqual(m.mariadb(self.target("mariadb"))["state"], "degraded")
        cursor.execute.assert_called_once_with("SHOW GLOBAL STATUS LIKE 'wsrep_%'")
        conn.close.assert_called_once()
        self.assertTrue(module.connect.call_args.kwargs["ssl_verify_identity"])
        self.assertEqual(module.connect.call_args.kwargs["ssl_ca"], "/ca")

    def test_redis_persistence_error_degraded(self):
        client, module = MagicMock(), MagicMock()
        module.Redis.return_value = client
        client.info.side_effect = [{"role": "master", "connected_slaves": 2},
                                   {"loading": 0, "rdb_last_bgsave_status": "err"}]
        with patch.dict(sys.modules, {"redis": module}):
            self.assertEqual(m.redis_check(self.target("redis"))["state"], "degraded")
        self.assertEqual([x.args[0] for x in client.info.call_args_list], ["replication", "persistence"])
        client.execute_command.assert_not_called()
        client.close.assert_called_once()

    def test_redis_missing_info_unknown(self):
        module = MagicMock()
        module.Redis.return_value.info.side_effect = [{"role": "master", "connected_slaves": 2}, {}]
        with patch.dict(sys.modules, {"redis": module}):
            self.assertEqual(m.redis_check(self.target("redis"))["state"], "unknown")

    def test_postgres_wrong_identity_degraded_readonly(self):
        module = MagicMock()
        conn = module.connect.return_value.__enter__.return_value
        cursor = conn.cursor.return_value.__enter__.return_value
        cursor.fetchone.side_effect = [(True, "db"), ("wrong",)]
        cursor.fetchall.return_value = [("streaming",)]
        target = {**self.target("postgresql"), "expected_role": "replica", "expected_system_identifier": "trusted"}
        with patch.dict(sys.modules, {"psycopg": module}):
            self.assertEqual(m.postgres(target)["state"], "degraded")
        self.assertIn("default_transaction_read_only=on", module.connect.call_args.kwargs["options"])
        self.assertEqual(module.connect.call_args.kwargs["sslmode"], "verify-full")
        self.assertTrue(all(x.args[0].startswith("SELECT ") for x in cursor.execute.call_args_list))

    def test_awx_ping_not_full_health(self):
        with patch.object(m, "get_json", return_value={"version": "24", "instances": []}):
            self.assertEqual(m.awx({"name": "awx", "url": "https://awx"})["state"], "unknown")

    def test_sentinel_disagrees_degraded(self):
        module = MagicMock()
        client = module.Redis.return_value
        client.sentinel_master.return_value = {"ip": "other", "port": 6379}
        client.execute_command.return_value = "OK 3 usable Sentinels"
        target = {**self.target("sentinel"), "master_name": "db", "expected_primary_host": "trusted", "expected_primary_port": 6379}
        with patch.dict(sys.modules, {"redis": module}):
            self.assertEqual(m.sentinel_check(target)["state"], "degraded")
        client.execute_command.assert_called_once_with("SENTINEL", "CKQUORUM", "db")


class RuntimeTests(unittest.TestCase):
    def test_stale_snapshot_unknown(self):
        value = m.Snapshot(m.validate({}))
        value.publish([m.result("db", "healthy", "ok")])
        self.assertTrue(value.read()["fresh"])
        value.finished = time.monotonic() - 10000
        self.assertFalse(value.read()["fresh"])
        self.assertEqual(value.read()["state"], "unknown")

    def test_readiness_independent_of_target_failure(self):
        snapshot = m.Snapshot(m.validate({}))
        snapshot.publish([m.result("db", "unavailable", "down")])
        cls = m.handler(snapshot)
        handler = cls.__new__(cls)
        handler.path = "/readyz"
        handler.wfile = io.BytesIO()
        handler.send_response = MagicMock()
        handler.send_header = MagicMock()
        handler.end_headers = MagicMock()
        handler.do_GET()
        handler.send_response.assert_called_once_with(200)
        self.assertTrue(json.loads(handler.wfile.getvalue())["ready"])
        self.assertFalse(hasattr(cls, "do_POST"))

    def test_hanging_workers_killed_and_other_checks_complete(self):
        config = m.validate({})
        config["check_deadline_seconds"] = 0.2
        start = time.monotonic()
        original = mp.get_context("spawn")
        context = types.SimpleNamespace(Queue=original.Queue,
            Process=lambda **kwargs: original.Process(target=time.sleep, args=(30,), daemon=True))
        with patch.object(m.mp, "get_context", return_value=context):
            values = m.run_checks(config)
        self.assertLess(time.monotonic() - start, 8)
        self.assertEqual(sum(x["reason"] == "check deadline exceeded" for x in values), 4)
        self.assertTrue(all(x["state"] == "unknown" for x in values))


class InfrastructureAdapterTests(unittest.TestCase):
    def test_empty_pvc_inventory_allowed(self):
        kube = MagicMock()
        kube.items.return_value = []
        self.assertEqual(m.inventory(kube, "pvcs", "/pvcs", m.pvc_check, allow_empty=True)["state"], "healthy")

    def test_empty_allowed_does_not_hide_api_failure(self):
        kube = MagicMock()
        kube.items.side_effect = urllib.error.HTTPError("https://api", 403, "denied", {}, None)
        self.assertEqual(m.inventory(kube, "pvcs", "/pvcs", m.pvc_check, allow_empty=True)["state"], "unknown")

    def test_unused_bound_pvc_not_degraded(self):
        obj = {"status": {"phase": "Bound", "conditions": [
            {"type": "Unused", "status": "True", "reason": "NoPodsUsingPVC"}]}}
        self.assertEqual(m.pvc_check(obj)["state"], "healthy")
        obj["status"]["conditions"].append({"type": "FileSystemResizePending", "status": "True"})
        self.assertEqual(m.pvc_check(obj)["state"], "degraded")

    def test_daemonset_list_without_kind_ready(self):
        obj = {"metadata": {"generation": 2}, "status": {
            "desiredNumberScheduled": 3, "numberReady": 3, "observedGeneration": 2}}
        self.assertEqual(m.workload_check(obj, "DaemonSet")["state"], "healthy")
        obj["status"]["numberReady"] = 2
        self.assertEqual(m.workload_check(obj, "DaemonSet")["state"], "degraded")

    def test_longhorn_faulted_volume_degraded(self):
        kube = MagicMock()
        def items(path):
            if path.endswith("/volumes"):
                return [{"metadata": {"name": "volume1"}, "status": {"robustness": "faulted", "state": "attached"}}]
            if path.endswith("/nodes"):
                return [{"status": {"conditions": {"Ready": {"type": "Ready", "status": "True"}}}}]
            return [{"status": {"phase": "Succeeded"}}]
        kube.items.side_effect = items
        with patch.object(m, "Kube", return_value=kube):
            self.assertEqual(m.longhorn({})["state"], "degraded")

    def test_missing_longhorn_crd_unknown(self):
        kube = MagicMock()
        kube.items.side_effect = urllib.error.HTTPError("https://api", 404, "missing", {}, None)
        with patch.object(m, "Kube", return_value=kube):
            self.assertEqual(m.longhorn({})["state"], "unknown")

    def test_metallb_allocated_address_does_not_claim_dataplane(self):
        kube = MagicMock()
        def items(path):
            if path.endswith("/services"):
                return [{"spec": {"type": "LoadBalancer"}, "status": {"loadBalancer": {"ingress": [{"ip": "10.0.0.1"}]}}}]
            if path.endswith("/deployments"):
                return [{"metadata": {"generation": 1}, "spec": {"replicas": 1}, "status": {"readyReplicas": 1, "observedGeneration": 1}}]
            if path.endswith("/daemonsets"):
                return [{"kind": "DaemonSet", "metadata": {"generation": 1}, "status": {"numberReady": 3, "desiredNumberScheduled": 3, "observedGeneration": 1}}]
            return [{}]
        kube.items.side_effect = items
        with patch.object(m, "Kube", return_value=kube):
            self.assertEqual(m.metallb({"namespaces": ["apps"]})["state"], "unknown")

    def test_stale_metrics_unknown(self):
        kube = MagicMock()
        kube.items.return_value = [{"metadata": {"name": "node"}, "timestamp": stamp(300), "usage": {"cpu": "1m", "memory": "1Mi"}}]
        with patch.object(m, "Kube", return_value=kube):
            self.assertEqual(m.metrics({"namespaces": ["apps"]})["state"], "unknown")

    def test_fresh_metrics_preserve_units(self):
        kube = MagicMock()
        kube.items.return_value = [{"metadata": {"name": "node"}, "timestamp": stamp(), "usage": {"cpu": "5m", "memory": "2Mi"}}]
        with patch.object(m, "Kube", return_value=kube):
            value = m.metrics({"namespaces": []})
        self.assertEqual(value["state"], "healthy")
        self.assertEqual(value["details"]["checks"][0]["details"]["checks"][0]["details"]["usage"]["memory"], "2Mi")


class ManifestTests(unittest.TestCase):
    def test_internal_readonly_manifest(self):
        try:
            import yaml
        except ImportError:
            self.skipTest("PyYAML required for manifest semantic checks")
        docs = list(yaml.safe_load_all((Path(__file__).resolve().parents[1] / "k8s.yaml").read_text()))
        self.assertFalse(any(x["kind"] in ("Service", "Ingress", "Gateway", "PersistentVolumeClaim") for x in docs))
        for doc in docs:
            for rule in doc.get("rules", []):
                self.assertLessEqual(set(rule["verbs"]), {"get", "list"})
                self.assertNotIn("secrets", rule.get("resources", []))
            if doc["kind"] == "Deployment":
                spec = doc["spec"]["template"]["spec"]
                self.assertEqual(doc["metadata"]["namespace"], "apps")
                self.assertTrue(spec["securityContext"]["runAsNonRoot"])
                self.assertFalse(spec.get("hostNetwork", False))
                self.assertTrue(spec["containers"][0]["securityContext"]["readOnlyRootFilesystem"])
            if doc["kind"] == "ConfigMap":
                m.validate(json.loads(doc["data"]["config.json"]))
            if doc["kind"] == "NetworkPolicy":
                self.assertEqual(doc["spec"]["ingress"], [])


if __name__ == "__main__":
    unittest.main()
