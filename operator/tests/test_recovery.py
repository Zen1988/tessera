import copy
import datetime as dt
import json
from pathlib import Path
import sys
import unittest
import urllib.error
import types
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import recovery as r


def old_stamp(seconds=180):
    return (dt.datetime.now(dt.timezone.utc) - dt.timedelta(seconds=seconds)).isoformat()


class FakeAPI:
    def __init__(self):
        self.writes = []
        self.objects = {
            "/api/v1/namespaces/apps/configmaps/tessera-recovery-state": {
                "metadata": {"name": "tessera-recovery-state", "resourceVersion": "1"}, "data": {"state.json": "{}"}},
            "/apis/coordination.k8s.io/v1/namespaces/apps/leases/tessera-recovery-leader": {
                "metadata": {"name": "tessera-recovery-leader", "resourceVersion": "1"}, "spec": {}},
            "/apis/postgresql.cnpg.io/v1/namespaces/postgres/clusters/db": {
                "metadata": {"name": "db", "uid": "cluster-id", "resourceVersion": "1", "annotations": {}},
                "status": {"currentPrimary": "db-1", "targetPrimary": "db-1", "systemID": "trusted"}}}
        self.pod_list = []
        for number in range(1, 4):
            self.objects[f"/api/v1/nodes/node{number}"] = {"status": {"conditions": [{"type": "Ready", "status": "True"}]}}
            self.objects[f"/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/node{number}"] = {"spec": {"renewTime": r.utc()}}
            self.pod_list.append({"metadata": {"name": f"db-{number}", "uid": f"pod-{number}", "resourceVersion": "1",
                "ownerReferences": [{"kind": "Cluster", "name": "db", "uid": "cluster-id"}],
                "labels": {"cnpg.io/cluster": "db"}}, "spec": {"nodeName": f"node{number}", "volumes": [
                {"name": "pgdata", "persistentVolumeClaim": {"claimName": f"db-{number}"}}]}, "status": {
                "conditions": [{"type": "Ready", "status": "True" if number < 3 else "False"}],
                "containerStatuses": [{"name": "postgres", "restartCount": 0 if number < 3 else 8,
                    "state": {"waiting": {"reason": "CrashLoopBackOff"}}}]}})
        self.objects["/api/v1/namespaces/postgres/persistentvolumeclaims/db-3"] = {
            "metadata": {"name": "db-3", "uid": "pvc-3", "resourceVersion": "1", "ownerReferences": [
                {"kind": "Cluster", "name": "db", "uid": "cluster-id"}], "annotations": {}}, "status": {"phase": "Bound"}}
        self.sql = {
            "db-1": {"replica": False, "system_id": "trusted", "timeline": 7,
                     "replicas": [{"name": "db-2", "state": "streaming", "lag": 0}]},
            "db-2": {"replica": True, "system_id": "trusted", "timeline": 7, "receivers": ["streaming"]}}
        self.log = "FATAL: requested timeline 6 is not a child of this server's history"

    def get(self, path):
        if path not in self.objects:
            raise urllib.error.HTTPError(path, 404, "missing", {}, None)
        return copy.deepcopy(self.objects[path])

    def items(self, path):
        return copy.deepcopy(self.pod_list)

    def logs(self, *args, **kwargs):
        return self.log

    def postgres(self, namespace, pod):
        return copy.deepcopy(self.sql[pod])

    def request(self, method, path, body):
        self.writes.append((method, path, copy.deepcopy(body)))
        if method == "PUT":
            previous = self.objects.get(path, {}).get("metadata", {}).get("resourceVersion", "1")
            if body["metadata"].get("resourceVersion") != previous:
                raise urllib.error.HTTPError(path, 409, "conflict", {}, None)
            obj = copy.deepcopy(body)
            obj["metadata"]["resourceVersion"] = str(int(previous) + 1)
            self.objects[path] = obj
            return obj
        if method == "POST" and path.endswith("/eviction"):
            name = body["metadata"]["name"]
            self.pod_list = [pod for pod in self.pod_list if pod["metadata"]["name"] != name]
            return {"status": "Success"}
        raise AssertionError("unexpected mutation")


def config():
    return {"namespace": "apps", "policies": [{"name": "pg", "kind": "cnpg-preserve-replace",
        "namespace": "postgres", "cluster": "db", "expected_identity": "trusted"}]}


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.api = FakeAPI()
        self.controller = r.Controller(config(), self.api)
        self.policy = config()["policies"][0]

    def state(self):
        return json.loads(self.api.objects[self.controller.base]["data"]["state.json"])

    def age_operation(self):
        data = self.state()
        data["pg"]["first_seen"] = old_stamp()
        self.api.objects[self.controller.base]["data"]["state.json"] = json.dumps(data)

    def prepare_eviction(self):
        self.controller.tick()
        self.age_operation()
        for _ in range(5):
            self.controller.tick()
        self.assertEqual(self.state()["pg"]["phase"], "evicting")

    def target_writes(self):
        return [item for item in self.api.writes if "/leases/" not in item[1] and "/configmaps/" not in item[1]]

    def missing_wal(self, segment="0000000900000001000000BD", stamp=None):
        pod = self.api.pod_list[2]
        pod["status"]["phase"] = "Running"
        status = pod["status"]["containerStatuses"][0]
        status.update(restartCount=0, state={"running": {"startedAt": old_stamp(900)}})
        def event(message, backend, severity):
            return json.dumps({"ts": stamp or r.utc(), "logger": "postgres", "logging_pod": "db-3",
                "record": {"message": message, "backend_type": backend, "error_severity": severity}})
        self.api.log = event("could not receive data from WAL stream: ERROR:  requested WAL segment " + segment + " has already been removed", "walreceiver", "FATAL") + "\n" + event("waiting for WAL to become available at 1/BD002000", "startup", "LOG")

    def test_running_missing_wal_preserved_before_eviction(self):
        self.missing_wal()
        self.prepare_eviction()
        self.assertEqual(self.state()["pg"]["diagnosis"], "postgres-missing-wal:0000000900000001000000BD")
        self.controller.tick()
        self.assertEqual(self.state()["pg"]["phase"], "waiting")
        self.assertFalse(any(method == "DELETE" for method, _, _ in self.api.writes))

    def test_missing_wal_uses_current_logs_and_requires_confirmation(self):
        self.missing_wal()
        with patch.object(self.api, "logs", wraps=self.api.logs) as logs:
            for _ in range(4):
                self.controller.tick()
            self.assertFalse(logs.call_args.kwargs["previous"])
        self.assertEqual(self.state()["pg"]["phase"], "confirmed")
        self.assertEqual(self.target_writes(), [])

    def test_missing_wal_rejects_stale_or_unstructured_logs(self):
        for stamp in (old_stamp(300), old_stamp(-300), "invalid"):
            self.missing_wal(stamp=stamp)
            self.assertIsNone(self.controller.classify(self.policy, self.api.pod_list[2]))
        self.api.log = "requested WAL segment 0000000900000001000000BD has already been removed"
        self.assertIsNone(self.controller.classify(self.policy, self.api.pod_list[2]))

    def test_missing_wal_progress_or_recovered_target_stops_action(self):
        self.missing_wal()
        self.controller.tick()
        self.age_operation()
        self.missing_wal(segment="0000000900000001000000BE")
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])
        self.api.pod_list[2]["status"]["conditions"][0]["status"] = "True"
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])

    def test_missing_wal_requires_healthy_survivor_and_unique_failure(self):
        self.missing_wal()
        self.api.sql["db-2"]["receivers"] = []
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])

    def test_startup_only_is_degraded_not_automatic_recovery(self):
        self.missing_wal()
        self.api.log = self.api.log.splitlines()[-1]
        self.assertEqual(self.controller.tick()["state"], "degraded")
        self.assertEqual(self.target_writes(), [])

    def test_handoff_reads_completed_logs_without_recent_filter(self):
        self.prepare_join_handoff()
        with patch.object(self.api, "logs", wraps=self.api.logs) as logs:
            self.controller.tick()
        self.assertEqual(logs.call_args.args[2], "join")
        self.assertEqual(logs.call_args.kwargs, {"previous": False})
        self.assertEqual(self.state()["pg"]["restored_pvc_ownership"], ["db-3"])

    def test_http_status_reported_without_sensitive_body_or_url(self):
        error = urllib.error.HTTPError("https://host/apis/x/clusters/db?token=secret", 409, "secret", {}, None)
        with patch.object(self.controller, "step", side_effect=error):
            value = self.controller.tick()
        self.assertIn("cluster request failed: HTTP 409", value["reason"])
        self.assertNotIn("secret", json.dumps(value))
        self.assertNotIn("https", json.dumps(value))

    def test_fence_refresh_preserves_concurrent_status_and_annotations(self):
        path, original = self.controller.cluster(self.policy)
        self.api.objects[path]["metadata"]["resourceVersion"] = "2"
        self.api.objects[path]["metadata"]["annotations"]["admin-note"] = "keep"
        self.controller.fence(path, original, "db-3", True)
        self.assertEqual(self.api.objects[path]["metadata"]["annotations"]["admin-note"], "keep")

    def test_fence_refresh_rejects_changed_authority_or_fence(self):
        path, original = self.controller.cluster(self.policy)
        for key, value in (("currentPrimary", "db-2"), ("systemID", "other")):
            self.api.objects[path]["status"][key] = value
            with self.assertRaises(r.Blocked):
                self.controller.fence(path, original, "db-3", False)
            self.api.objects[path]["status"] = copy.deepcopy(original["status"])
        self.api.objects[path]["metadata"]["annotations"][r.FENCE] = '["*"]'
        with self.assertRaises(r.Blocked):
            self.controller.fence(path, original, "db-3", False)
        self.assertEqual(self.target_writes(), [])

    def test_log_window_only_for_explicit_recent_detection(self):
        import io
        api = r.API.__new__(r.API)
        api.base = "https://cluster"
        api.get = MagicMock(return_value={})
        opener = MagicMock()
        with patch.object(r.ssl, "create_default_context"), patch.object(r.urllib.request, "build_opener", return_value=opener), patch.object(r.Path, "read_text", return_value="test-token"):
            for recent in (False, True):
                opener.open.return_value = io.BytesIO(b"{}")
                api.logs("postgres", "join-pod", "join", previous=False, recent=recent)
                query = r.urllib.parse.parse_qs(r.urllib.parse.urlsplit(opener.open.call_args.args[0].full_url).query)
                self.assertEqual("sinceSeconds" in query, recent)
                self.assertEqual(query["previous"], ["false"])

    def test_recovery_policy_requires_explicit_identity(self):
        value = config()
        value["policies"][0]["expected_identity"] = ""
        with self.assertRaises(ValueError):
            r.validate(value)

    def test_unknown_actions_rejected(self):
        value = config()
        value["policies"][0]["kind"] = "run-shell"
        with self.assertRaises(ValueError):
            r.validate(value)

    def test_unrecognized_logs_never_mutate_target(self):
        self.api.log = "password=secret; random error"
        value = self.controller.tick()
        self.assertEqual(self.target_writes(), [])
        self.assertNotIn("password", json.dumps(value))

    def test_fresh_confirmations_required(self):
        for _ in range(4):
            self.controller.tick()
        self.assertEqual(self.state()["pg"]["phase"], "confirmed")
        self.assertEqual(self.target_writes(), [])

    def test_stale_node_blocks_action(self):
        path = "/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/node3"
        self.api.objects[path]["spec"]["renewTime"] = old_stamp(300)
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])

    def test_second_primary_blocks_action(self):
        self.api.sql["db-2"]["replica"] = False
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])

    def test_different_timeline_blocks_action(self):
        self.api.sql["db-2"]["timeline"] = 8
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])

    def test_nonstreaming_survivor_blocks_action(self):
        self.api.sql["db-1"]["replicas"][0]["state"] = "catchup"
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])

    def test_explicit_identity_mismatch_blocks_action(self):
        self.api.sql["db-1"]["system_id"] = "other"
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])

    def test_existing_administrator_fence_blocks_action(self):
        path, cluster = self.controller.cluster(self.policy)
        self.api.objects[path]["metadata"]["annotations"][r.FENCE] = '["db-3"]'
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])

    def test_other_controller_lease_blocks_action(self):
        self.api.objects[self.controller.lease]["spec"] = {"holderIdentity": "other", "renewTime": r.utc()}
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.api.writes, [])

    def test_native_preservation_precedes_eviction(self):
        self.prepare_eviction()
        pvc = self.api.get("/api/v1/namespaces/postgres/persistentvolumeclaims/db-3")
        self.assertEqual(pvc["metadata"]["ownerReferences"], [])
        self.assertEqual(pvc["metadata"]["annotations"][r.DETACHED], "detached")
        self.assertEqual(self.state()["pg"]["preserved"], ["db-3"])
        self.assertFalse(any(method in ("DELETE", "POST") for method, _, _ in self.target_writes()))
        self.controller.tick()
        evictions = [item for item in self.target_writes() if item[0] == "POST"]
        self.assertEqual(len(evictions), 1)
        self.assertEqual(evictions[0][2]["deleteOptions"]["preconditions"]["uid"], "pod-3")

    def test_unrelated_pvc_owner_blocks_detachment(self):
        self.controller.tick()
        self.age_operation()
        self.controller.tick()
        self.controller.tick()
        self.controller.tick()
        pvc = self.api.objects["/api/v1/namespaces/postgres/persistentvolumeclaims/db-3"]
        pvc["metadata"]["ownerReferences"][0]["uid"] = "other-cluster"
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertFalse(any("persistentvolumeclaims" in path for _, path, _ in self.target_writes()))

    def test_restart_after_preservation_resumes(self):
        self.prepare_eviction()
        new = r.Controller(config(), self.api)
        new.identity = self.controller.identity  # simulate same leader's resumed reconciliation
        new.tick()
        self.assertEqual(self.state()["pg"]["phase"], "waiting")
        self.assertEqual(len([x for x in self.target_writes() if "persistentvolumeclaims" in x[1]]), 1)

    def test_lost_eviction_response_resumes_without_duplicate(self):
        self.prepare_eviction()
        self.api.pod_list = self.api.pod_list[:2]
        self.controller.tick()
        self.assertEqual(self.state()["pg"]["phase"], "unfencing")
        self.assertFalse(any(x[0] == "POST" for x in self.target_writes()))

    def test_completed_replacement_requires_streaming_all_members(self):
        self.prepare_eviction()
        self.controller.tick()
        self.controller.tick()
        pod = copy.deepcopy(self.api.pod_list[1])
        pod["metadata"].update(name="db-4", uid="pod-4")
        self.api.pod_list.append(pod)
        self.api.sql["db-4"] = copy.deepcopy(self.api.sql["db-2"])
        self.api.sql["db-1"]["replicas"].append({"name": "db-4", "state": "streaming", "lag": 0})
        self.controller.tick()
        self.assertEqual(self.state()["pg"]["phase"], "completed")
        self.assertIn("/api/v1/namespaces/postgres/persistentvolumeclaims/db-3", self.api.objects)
        self.assertEqual(self.controller.tick()["state"], "healthy")

    def test_all_mutations_are_bounded_native_operations(self):
        self.prepare_eviction()
        self.controller.tick()
        self.assertFalse(any(method == "DELETE" for method, _, _ in self.api.writes))
        self.assertFalse(any("force" in json.dumps(body).lower() for _, _, body in self.api.writes))

    def test_pvc_replaced_with_same_name_is_not_detached(self):
        self.controller.tick()
        self.age_operation()
        self.controller.tick()
        self.controller.tick()
        self.controller.tick()
        self.api.objects["/api/v1/namespaces/postgres/persistentvolumeclaims/db-3"]["metadata"]["uid"] = "new-volume"
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertFalse(any("persistentvolumeclaims" in path for _, path, _ in self.target_writes()))

    def test_spoofed_cluster_label_does_not_authorize_recovery(self):
        self.api.pod_list[2]["metadata"]["ownerReferences"] = []
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])

    def test_process_restart_waits_for_lease_then_resumes(self):
        self.prepare_eviction()
        replacement = r.Controller(config(), self.api)
        self.assertEqual(replacement.tick()["state"], "unknown")
        self.api.objects[replacement.lease]["spec"]["renewTime"] = old_stamp(180)
        replacement.tick()
        self.assertEqual(self.state()["pg"]["phase"], "waiting")
        self.assertEqual(len([x for x in self.target_writes() if "persistentvolumeclaims" in x[1]]), 1)

    def test_removed_fence_blocks_eviction(self):
        self.prepare_eviction()
        path, _ = self.controller.cluster(self.policy)
        self.api.objects[path]["metadata"]["annotations"][r.FENCE] = "[]"
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertFalse(any(x[0] == "POST" for x in self.target_writes()))

    def test_new_primary_reconfirmed_automatically(self):
        self.controller.tick()
        self.age_operation()
        path, _ = self.controller.cluster(self.policy)
        self.api.objects[path]["status"].update(currentPrimary="db-2", targetPrimary="db-2")
        self.api.sql["db-2"] = {"replica": False, "system_id": "trusted", "timeline": 8,
            "replicas": [{"name": "db-1", "state": "streaming", "lag": 0}]}
        self.api.sql["db-1"] = {"replica": True, "system_id": "trusted", "timeline": 8, "receivers": ["streaming"]}
        self.controller.tick()
        data = self.state()
        data["pg"]["source_changed_at"] = old_stamp()
        self.api.objects[self.controller.base]["data"]["state.json"] = json.dumps(data)
        self.controller.tick()
        self.controller.tick()
        self.assertEqual(self.state()["pg"]["source"], "db-2")
        self.assertEqual(self.target_writes(), [])

    def test_join_job_is_not_a_database_member(self):
        job = copy.deepcopy(self.api.pod_list[2])
        job["metadata"].update(name="db-3-join-random", uid="join-job-pod")
        job["metadata"]["ownerReferences"] = [{"kind": "Job", "name": "db-3-join"}]
        job["status"]["phase"] = "Succeeded"
        self.api.pod_list.append(job)
        self.assertEqual(len(self.controller.pods(self.policy)), 3)
        self.controller.tick()
        self.assertEqual(self.state()["pg"]["phase"], "confirmed")

    def test_reused_instance_name_with_new_uid_exits_waiting(self):
        self.prepare_eviction()
        old = copy.deepcopy(self.api.pod_list[2])
        self.controller.tick()
        old["metadata"]["uid"] = "replacement-pod-3"
        self.api.pod_list.append(old)
        self.controller.tick()
        self.assertEqual(self.state()["pg"]["phase"], "unfencing")

    def test_completed_join_job_does_not_block_verified_replacement(self):
        self.prepare_eviction()
        self.controller.tick()
        self.controller.tick()
        replacement = copy.deepcopy(self.api.pod_list[1])
        replacement["metadata"].update(name="db-4", uid="replacement-4")
        self.api.pod_list.append(replacement)
        self.api.sql["db-4"] = copy.deepcopy(self.api.sql["db-2"])
        self.api.sql["db-1"]["replicas"].append({"name": "db-4", "state": "streaming", "lag": 0})
        job = copy.deepcopy(replacement)
        job["metadata"]["name"] = "db-4-join-random"
        job["metadata"]["ownerReferences"] = [{"kind": "Job", "name": "db-4-join"}]
        job["status"].update(phase="Succeeded", conditions=[{"type": "Ready", "status": "False"}])
        self.api.pod_list.append(job)
        self.controller.tick()
        self.assertEqual(self.state()["pg"]["phase"], "completed")

    def test_join_job_alone_cannot_complete_recovery(self):
        self.prepare_eviction()
        self.controller.tick()
        self.controller.tick()
        self.controller.tick()
        self.assertEqual(self.state()["pg"]["phase"], "unfencing")

    def prepare_join_handoff(self):
        self.prepare_eviction()
        self.controller.tick()
        self.controller.tick()
        job = {"metadata": {"name": "db-3-join", "uid": "join-job", "creationTimestamp": old_stamp(30),
            "ownerReferences": [{"kind": "Cluster", "name": "db", "uid": "cluster-id"}]},
            "spec": {"template": {"spec": {"volumes": [{"name": "pgdata", "persistentVolumeClaim": {"claimName": "db-3"}}]}}},
            "status": {"succeeded": 1, "conditions": [{"type": "Complete", "status": "True"}]}}
        self.api.objects["/apis/batch/v1/namespaces/postgres/jobs/db-3-join"] = job
        pod = copy.deepcopy(self.api.pod_list[1])
        pod["metadata"].update(name="db-3-join-pod", uid="join-pod", ownerReferences=[{"kind": "Job", "uid": "join-job"}])
        pod["status"].update(phase="Succeeded", conditions=[{"type": "Ready", "status": "False"}])
        self.api.pod_list.append(pod)
        self.api.log = '\n'.join([json.dumps({"msg": "renaming the data directory", "pgdataNewName": "/var/lib/postgresql/data/pgdata_20261022T080500Z"}),
            json.dumps({"logger": "pg_basebackup", "msg": "pg_basebackup: base backup completed"})])

    def test_verified_join_restores_native_pvc_ownership_not_ready_flag(self):
        self.prepare_join_handoff()
        self.controller.tick()
        pvc = self.api.get("/api/v1/namespaces/postgres/persistentvolumeclaims/db-3")
        self.assertEqual(pvc["metadata"]["ownerReferences"][0]["uid"], "cluster-id")
        self.assertEqual(pvc["metadata"]["annotations"][r.DETACHED], "detached")
        self.assertEqual(self.state()["pg"]["restored_pvc_ownership"], ["db-3"])
        self.assertEqual(self.state()["pg"]["phase"], "unfencing")
        self.assertIn("not an independent backup", self.state()["pg"]["preservation_mode"])

    def test_no_old_directory_evidence_no_adoption(self):
        self.prepare_join_handoff()
        self.api.log = json.dumps({"logger": "pg_basebackup", "msg": "base backup completed"})
        self.assertEqual(self.controller.tick()["state"], "unknown")
        pvc = self.api.get("/api/v1/namespaces/postgres/persistentvolumeclaims/db-3")
        self.assertEqual(pvc["metadata"]["ownerReferences"], [])

    def test_foreign_join_job_cannot_adopt_pvc(self):
        self.prepare_join_handoff()
        self.api.objects["/apis/batch/v1/namespaces/postgres/jobs/db-3-join"]["metadata"]["ownerReferences"][0]["uid"] = "foreign"
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.api.get("/api/v1/namespaces/postgres/persistentvolumeclaims/db-3")["metadata"]["ownerReferences"], [])

    def test_handoff_pvc_identity_change_blocks_adoption(self):
        self.prepare_join_handoff()
        self.api.objects["/api/v1/namespaces/postgres/persistentvolumeclaims/db-3"]["metadata"]["uid"] = "different-volume"
        self.assertEqual(self.controller.tick()["state"], "unknown")
        self.assertEqual(self.api.get("/api/v1/namespaces/postgres/persistentvolumeclaims/db-3")["metadata"]["ownerReferences"], [])

    def test_same_name_database_returns_after_join_and_completes(self):
        self.prepare_join_handoff()
        self.controller.tick()
        replacement = copy.deepcopy(self.api.pod_list[1])
        replacement["metadata"].update(name="db-3", uid="replacement-3")
        self.api.pod_list.append(replacement)
        self.api.sql["db-3"] = copy.deepcopy(self.api.sql["db-2"])
        self.api.sql["db-1"]["replicas"].append({"name": "db-3", "state": "streaming", "lag": 0})
        self.controller.tick()
        self.assertEqual(self.state()["pg"]["phase"], "completed")
        self.assertEqual(len(self.controller.pods(self.policy)), 3)


class GaleraTests(unittest.TestCase):
    setUp = RecoveryTests.setUp
    state = RecoveryTests.state
    target_writes = RecoveryTests.target_writes
    def galera(self):
        policy = {"name": "galera", "kind": "galera-rejoin", "namespace": "mariadb",
            "cluster": "db", "expected_identity": "trusted", "member_dns": "{pod}.db.mariadb.svc",
            "credentials": {"secret": "db-root", "password_key": "password", "ca_secret": "db-ca", "ca_key": "ca.crt"}}
        cluster = {"metadata": {"name": "db", "uid": "galera-id", "resourceVersion": "1"}, "spec": {"galera": {"recovery": {"enabled": True}}}}
        self.api.objects["/apis/k8s.mariadb.com/v1alpha1/namespaces/mariadb/mariadbs/db"] = cluster
        for pod in self.api.pod_list:
            pod["metadata"]["labels"] = {"app.kubernetes.io/instance": "db"}
            pod["metadata"]["ownerReferences"] = [{"kind": "StatefulSet", "name": "db", "uid": "sts"}]
            pod["status"]["containerStatuses"][0]["name"] = "mariadb"
        self.api.objects["/api/v1/namespaces/mariadb/persistentvolumeclaims/db-3"] = copy.deepcopy(self.api.objects["/api/v1/namespaces/postgres/persistentvolumeclaims/db-3"])
        self.api.log = "WSREP: failed to open gcomm backend connection"
        self.galera_status = {"uuid": "trusted", "component": "Primary", "synced": True, "ready": True, "connected": True, "size": 2}
        self.api.galera = lambda policy, pod: copy.deepcopy(self.galera_status)
        return r.Controller({"namespace": "apps", "policies": [policy]}, self.api)

    def test_galera_no_primary_component_no_restart(self):
        controller = self.galera()
        self.galera_status["component"] = "Non-Primary"
        self.assertEqual(controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])

    def test_galera_wrong_uuid_no_restart(self):
        controller = self.galera()
        self.galera_status["uuid"] = "other"
        self.assertEqual(controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])

    def test_galera_confirmed_rejoin_only_evicts_preserves_all_pvcs(self):
        controller = self.galera()
        controller.tick()
        data = self.state()
        data["galera"]["first_seen"] = old_stamp()
        self.api.objects[controller.base]["data"]["state.json"] = json.dumps(data)
        controller.tick()
        controller.tick()
        controller.tick()
        writes = self.target_writes()
        self.assertEqual(len(writes), 1)
        self.assertTrue(writes[0][1].endswith("/db-3/eviction"))

    def test_galera_forced_native_bootstrap_blocks_restart(self):
        controller = self.galera()
        self.api.objects["/apis/k8s.mariadb.com/v1alpha1/namespaces/mariadb/mariadbs/db"]["spec"]["galera"]["recovery"]["forceClusterBootstrapInPod"] = "db-1"
        self.assertEqual(controller.tick()["state"], "unknown")
        self.assertEqual(self.target_writes(), [])


class TransportTests(unittest.TestCase):
    def execute(self, frames):
        client = MagicMock()
        client.recv.side_effect = frames
        module = types.SimpleNamespace(create_connection=MagicMock(return_value=client))
        fake_sa = MagicMock()
        (fake_sa / "token").read_text.return_value = "do-not-log-token"
        with patch.dict(sys.modules, {"websocket": module}), patch.object(r, "SA", fake_sa), patch.object(r.API, "get", return_value={}):
            value = r.API().postgres("postgres", "db-1")
        return value, module, client

    def test_exec_uses_fixed_readonly_sql_verified_tls(self):
        value, module, client = self.execute([b'\x01{"replica": false, "system_id":"trusted"}\n', b'\x03{"status":"Success"}'])
        self.assertFalse(value["replica"])
        kwargs = module.create_connection.call_args.kwargs
        self.assertEqual(kwargs["sslopt"]["cert_reqs"], r.ssl.CERT_REQUIRED)
        self.assertTrue(kwargs["sslopt"]["check_hostname"])
        self.assertIn("default_transaction_read_only", module.create_connection.call_args.args[0])
        client.close.assert_called_once()

    def test_exec_failure_does_not_echo_remote_secret_text(self):
        with self.assertRaises(r.Blocked) as error:
            self.execute([b'\x02password=secret', b'\x03{"status":"Failure", "message":"password=secret"}'])
        self.assertNotIn("secret", str(error.exception))

    def test_exec_requires_explicit_success(self):
        with self.assertRaises(r.Blocked):
            self.execute([b'\x01{"replica":false}\n', b''])


if __name__ == "__main__":
    unittest.main()
