"""Offline safety tests; no database, services or native install are touched."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "upgrade-otobo111-source.py"
SPEC = importlib.util.spec_from_file_location("otobo_upgrade", SCRIPT)
UPGRADE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(UPGRADE)

def prepared_report():
    manifest = json.loads((SCRIPT.parents[1] / "var/tessera/compatibility/otobo-11.1.1.json").read_text())
    keys = ("path", "native_path", "owner", "current_native_sha256",
            "target_native_sha256", "override_sha256", "reviewed")
    return [{**{key: entry[key] for key in keys}, "reviewed": False}
            for entry in manifest["entries"]]


class UpgradeSafety(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.home = self.root / "otobo"
        self.stage = self.root / "stable"
        self.home.mkdir()
        self.stage.mkdir()

    def put(self, root, name, data):
        target = root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        return target

    def opm(self, *paths):
        return ("<otobo_package><Filelist>" + "".join(
            f'<File Location="{path}"/>' for path in paths
        ) + "</Filelist></otobo_package>").encode()

    def test_changed_native_shadow_requires_review(self):
        self.put(self.home, "Kernel/System/User.pm", b"beta")
        self.put(self.home, "Custom/Kernel/System/User.pm", b"tessera")
        self.put(self.stage, "Kernel/System/User.pm", b"stable")
        report = UPGRADE.audit(self.home, self.stage, self.opm())
        self.assertEqual(len(report), 1)
        self.assertFalse(report[0]["reviewed"])
        self.assertEqual(report[0]["override_sha256"], hashlib.sha256(b"tessera").hexdigest())
        self.assertFalse(UPGRADE.compatible(report, report))

    def test_unchanged_upstream_does_not_add_new_conflict(self):
        self.put(self.home, "Kernel/System/User.pm", b"same")
        self.put(self.home, "Custom/Kernel/System/User.pm", b"tessera")
        self.put(self.stage, "Kernel/System/User.pm", b"same")
        self.assertEqual(UPGRADE.audit(self.home, self.stage, self.opm()), [])

    def test_direct_package_core_collision_is_reviewed(self):
        self.put(self.home, "Kernel/System/User.pm", b"tessera")
        self.put(self.stage, "Kernel/System/User.pm", b"stable")
        report = UPGRADE.audit(self.home, self.stage, self.opm("Kernel/System/User.pm"))
        self.assertEqual(report[0]["path"], "Kernel/System/User.pm")

    def test_missing_deployed_overlay_fails_closed(self):
        self.put(self.home, "Kernel/System/User.pm", b"same")
        self.put(self.stage, "Kernel/System/User.pm", b"same")
        report = UPGRADE.audit(self.home, self.stage,
            self.opm("var/governancedb/runtime_overlay/Kernel/System/User.pm"))
        self.assertIsNone(report[0]["override_sha256"])

    def test_exact_approval_required(self):
        report = [{"path": "Custom/a", "override_sha256": "old", "reviewed": False}]
        approved = [dict(report[0], reviewed=True)]
        self.assertTrue(UPGRADE.compatible(report, approved))
        self.assertFalse(UPGRADE.compatible(report, []))
        self.assertFalse(UPGRADE.compatible(report, approved + approved))
        self.assertFalse(UPGRADE.compatible(report, [dict(approved[0], override_sha256="new")]))

    def test_wrong_archive_rejected(self):
        archive = self.put(self.root, "wrong.tar.gz", b"wrong source")
        with self.assertRaisesRegex(RuntimeError, "differs"):
            UPGRADE.verify_archive(archive)

    def test_partial_upgrade_cannot_apply_or_start(self):
        state = self.root / "state"
        state.mkdir()
        (state / "state.json").write_text(json.dumps({"phase": "APPLYING",
            "home": str(self.home), "stage": str(self.stage)}))
        args = type("Args", (), {"state": state})()
        with patch.object(UPGRADE, "run") as execute:
            with self.assertRaisesRegex(RuntimeError, "Not PREPARED"):
                UPGRADE.apply(args)
            with self.assertRaisesRegex(RuntimeError, "fully completed"):
                UPGRADE.start(args)
            execute.assert_not_called()

    def test_unsupported_version_rejected_before_state_creation(self):
        self.put(self.home, "RELEASE", b"VERSION = 11.0.18\n")
        state = self.root / "state"
        args = type("Args", (), {"home": self.home, "state": state})()
        with self.assertRaisesRegex(RuntimeError, "beta1/2/3"):
            UPGRADE.prepare(args)
        self.assertFalse(state.exists())

    def test_state_inside_application_rejected(self):
        args = type("Args", (), {"home": self.home, "state": self.home / "backup"})()
        with self.assertRaisesRegex(RuntimeError, "outside"):
            UPGRADE.prepare(args)

    def test_console_uses_native_command_before_global_options(self):
        # Leading --no-ansi would silently invoke List instead of the migration work.
        with patch.object(UPGRADE, "as_otobo") as execute:
            UPGRADE.console(self.home, "Maint::Config::Rebuild")
        self.assertEqual(execute.call_args.args[2], "Maint::Config::Rebuild")
        self.assertEqual(execute.call_args.args[-1], "--no-ansi")

    def test_reviewed_package_accepts_actual_host_report(self):
        root = SCRIPT.parents[1]
        package = root / "Kernel/Package/TESSERA-Base-0.1.10.opm"
        report = prepared_report()
        data, files, entries = UPGRADE.compatibility_package(package, report)
        self.assertEqual(len(entries), 38)
        self.assertTrue(data)
        self.assertIn("Kernel/System/GovernanceDB/Bootstrap.pm", files)

    def test_package_rejects_unreviewed_host_drift(self):
        root = SCRIPT.parents[1]
        package = root / "Kernel/Package/TESSERA-Base-0.1.10.opm"
        report = prepared_report()
        report[0]["override_sha256"] = "0" * 64
        with self.assertRaisesRegex(RuntimeError, "do not match"):
            UPGRADE.compatibility_package(package, report)

    def test_package_rejects_extra_conflict(self):
        root = SCRIPT.parents[1]
        package = root / "Kernel/Package/TESSERA-Base-0.1.10.opm"
        report = prepared_report()
        report.append(dict(report[-1], path="Custom/Kernel/Modules/Unexpected.pm"))
        with self.assertRaisesRegex(RuntimeError, "do not match"):
            UPGRADE.compatibility_package(package, report)

    def test_tessera_restored_after_other_package_repair(self):
        relative = "Custom/Kernel/Modules/Example.pm"
        target = self.put(self.home, relative, b"old")
        merged = b"merged stable runtime"
        entries = [{"path": relative, "merged_sha256": hashlib.sha256(merged).hexdigest()}]
        actions = []
        def install(home, data, operation):
            actions.append(operation)
            target.write_bytes(merged)
        def repair(home, operation):
            actions.append(operation)
            target.write_bytes(b"older other-package implementation")
        with patch.object(UPGRADE, "with_package", side_effect=install), \
             patch.object(UPGRADE, "console", side_effect=repair), \
             patch.object(UPGRADE, "package_export", return_value=b"reviewed opm"):
            UPGRADE.upgrade_packages(self.home, b"reviewed opm", {}, entries)
        self.assertEqual(actions, ["Admin::Package::Upgrade", "Admin::Package::ReinstallAll",
                                   "Admin::Package::Reinstall"])
        self.assertEqual(target.read_bytes(), merged)

    def test_incomplete_package_restore_cannot_report_success(self):
        relative = "Custom/Kernel/Modules/Example.pm"
        self.put(self.home, relative, b"old")
        entries = [{"path": relative, "merged_sha256": hashlib.sha256(b"merged").hexdigest()}]
        with patch.object(UPGRADE, "with_package"), patch.object(UPGRADE, "console"):
            with self.assertRaisesRegex(RuntimeError, "runtime mismatch"):
                UPGRADE.upgrade_packages(self.home, b"reviewed opm", {}, entries)


if __name__ == "__main__":
    unittest.main()
