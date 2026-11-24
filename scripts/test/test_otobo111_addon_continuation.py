"""Offline tests for the paused native package-stage continuation."""
import base64
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("continuation", ROOT / "scripts/continue-otobo111-addons.py")
C = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(C)


class ContinuationSafety(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)
        self.entries = [
            ({"name": "Vendor", "from": "11.0.2", "version": "11.1.1",
              "sha256": "new", "dependencies": [{"name": "Core", "minimum": "11.1.1"}]}, b"vendor"),
            ({"name": "TESSERA-Base", "from": "0.1.10", "version": "0.1.11",
              "sha256": "base-new", "dependencies": [{"name": "Vendor", "minimum": "11.1.1"}]}, b"base")]
        self.current = {
            "Vendor": {"version": "11.0.2", "sha256": "old", "compatible": 0},
            "Core": {"version": "11.1.4", "sha256": "core", "compatible": 1},
            "TESSERA-Base": {"version": "0.1.10", "sha256": C.OLD_BASE_SHA, "compatible": 1}}

    def test_supported_dependency_plan(self):
        C.validate_plan(self.current, self.entries)
        self.assertEqual(C.version_key("11.1.0"), C.version_key("11.1"))

    def test_shipped_bundle_metadata_and_hashes(self):
        path = ROOT / "outputs/TESSERA-0.1.11-OTOBO-11.1.1-Addon-Continuation.zip"
        with zipfile.ZipFile(path) as archive:
            archive.extractall(self.path)
        plan, packages = C.load_bundle(self.path)
        self.assertEqual(len(packages), 6)
        self.assertEqual(packages[-1][0]["name"], "TESSERA-Base")
        self.assertEqual([p["version"] for p, _ in packages],
                         ["11.1.1", "11.1.1", "11.1.1", "11.1.2", "11.1.3", "0.1.11"])
        entry = plan["packages"][0]
        (self.path / entry["file"]).write_bytes(b"corrupt")
        with self.assertRaisesRegex(RuntimeError, "checksum"):
            C.load_bundle(self.path)

    def test_unreviewed_incompatible_package_stops(self):
        self.current["Other"] = {"version": "11.0.1", "compatible": 0}
        with self.assertRaisesRegex(RuntimeError, "Unreviewed incompatible"):
            C.validate_plan(self.current, self.entries)

    def test_dependency_not_satisfied_stops(self):
        self.current["Core"]["version"] = "11.1.0"
        with self.assertRaisesRegex(RuntimeError, "Unsatisfied dependency"):
            C.validate_plan(self.current, self.entries)

    def test_wrong_target_checksum_stops(self):
        self.current["Vendor"]["version"] = "11.1.1"
        with self.assertRaisesRegex(RuntimeError, "Target registry content"):
            C.validate_plan(self.current, self.entries)

    def test_inflight_hook_never_replayed(self):
        with self.assertRaisesRegex(RuntimeError, "requires inspection"):
            C.check_receipt({"plan_sha256": "same", "active": "upgrade:Vendor"}, "same")
        with self.assertRaisesRegex(RuntimeError, "differs"):
            C.check_receipt({"plan_sha256": "old"}, "new")

    def test_unjournaled_target_not_adopted(self):
        self.current["Vendor"].update(version="11.1.1", sha256="new")
        receipt = {"completed": [], "active": None}
        with patch.object(C, "inventory", return_value=self.current), \
             patch.object(C.U, "with_package") as upgrade:
            with self.assertRaisesRegex(RuntimeError, "Unjournaled"):
                C.execute(self.path, self.path, {}, self.path, receipt, self.entries)
            upgrade.assert_not_called()

    def test_failed_hook_leaves_active_receipt(self):
        receipt = {"completed": [], "active": None}
        with patch.object(C, "inventory", return_value=self.current), \
             patch.object(C.U, "with_package", side_effect=RuntimeError("hook failed")):
            with self.assertRaisesRegex(RuntimeError, "hook failed"):
                C.execute(self.path, self.path, {}, self.path, receipt, self.entries)
        saved = json.loads((self.path / "receipt.json").read_text())
        self.assertEqual(saved["active"], "upgrade:Vendor")
        self.assertEqual(saved["completed"], [])

    def test_completed_drift_rejected(self):
        receipt = {"completed": ["Vendor"], "active": None}
        with patch.object(C, "inventory", return_value=self.current):
            with self.assertRaisesRegex(RuntimeError, "Completed package drift"):
                C.execute(self.path, self.path, {}, self.path, receipt, self.entries)

    def test_core_stage_cannot_be_replayed(self):
        (self.path / "state.json").write_text(json.dumps({"phase": "APPLYING"}))
        with patch.object(C.U, "console") as console:
            with self.assertRaisesRegex(RuntimeError, "completed-core"):
                C.continue_upgrade(SimpleNamespace(state=self.path, bundle=self.path))
            console.assert_not_called()

    def test_empty_backup_receipt_rejected(self):
        (self.path / "backups.json").write_text("{}")
        with patch.object(C.U, "run") as run:
            with self.assertRaisesRegex(RuntimeError, "Incomplete"):
                C.checkpoint_backup(self.path, self.path, {}, self.path / "client")
            run.assert_not_called()

    def test_unknown_runtime_override_preserved_before_any_upgrade(self):
        target = self.path / "Custom/changed.pm"
        target.parent.mkdir()
        target.write_bytes(b"administrator")
        manifests = {
            "var/tessera/compatibility/otobo-11.1.1.json": {"entries": []},
            "var/tessera/compatibility/otobo-11.1.1-addons.json": {"overlaps": [{
                "path": "Custom/changed.pm", "allowed_sha256": ["known"]}]}}
        root = ET.Element("otobo_package")
        listing = ET.SubElement(root, "Filelist")
        for name, data in manifests.items():
            ET.SubElement(listing, "File", Location=name).text = base64.b64encode(json.dumps(data).encode()).decode()
        with self.assertRaisesRegex(RuntimeError, "Unknown runtime override"):
            C.runtime_preflight(self.path, ET.tostring(root))
        self.assertEqual(target.read_bytes(), b"administrator")

    def test_all_package_operations_then_base_last_and_finish(self):
        entries = copy.deepcopy(self.entries)
        payload = json.dumps({"entries": []}).encode()
        overlaps = json.dumps({"overlaps": []}).encode()
        entries[-1] = (entries[-1][0],
            b'<otobo_package><Filelist><File Location="var/tessera/compatibility/otobo-11.1.1.json">'
            + base64.b64encode(payload) + b'</File><File Location="var/tessera/compatibility/otobo-11.1.1-addons.json">'
            + base64.b64encode(overlaps) + b'</File></Filelist></otobo_package>')
        order = []
        def operation(home, data, command):
            index = 0 if data == b"vendor" else 1
            entry = entries[index][0]
            order.append((command, entry["name"]))
            self.current[entry["name"]].update(version=entry["version"], sha256=entry["sha256"], compatible=1)
        receipt = {"completed": [], "active": None}
        info = {"active_services": ["apache2.service"], "cron_present": True}
        with patch.object(C, "inventory", side_effect=lambda _: copy.deepcopy(self.current)), \
             patch.object(C.U, "with_package", side_effect=operation), \
             patch.object(C.U, "console", side_effect=lambda h, cmd: order.append((cmd, ""))), \
             patch.object(C.U, "finish_configuration", side_effect=lambda *a: order.append(("finish", ""))):
            C.execute(self.path, self.path, info, self.path, receipt, entries)
        self.assertEqual(order, [
            ("Admin::Package::Upgrade", "Vendor"), ("Admin::Package::Upgrade", "TESSERA-Base"),
            ("Admin::Package::ReinstallAll", ""), ("Admin::Package::Reinstall", "TESSERA-Base"), ("finish", "")])
        self.assertEqual(info["active_services"], ["apache2.service"])
        self.assertTrue(info["cron_present"])
        self.assertTrue(receipt["finished"])


if __name__ == "__main__":
    unittest.main()
