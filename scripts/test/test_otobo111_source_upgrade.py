"""Offline safety tests; no database, services or native install are touched."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import tarfile
from types import SimpleNamespace
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

    def test_backup_resume_is_unavailable_after_migration_begins(self):
        for phase in ("STOPPING", "APPLYING", "UPDATED_STOPPED", "STARTED_PENDING_ACCEPTANCE"):
            with self.assertRaisesRegex(RuntimeError, "requires BACKING_UP"):
                UPGRADE.backup_mode({"phase": phase}, True)
        self.assertTrue(UPGRADE.backup_mode({"phase": "BACKING_UP"}, True))
        with self.assertRaisesRegex(RuntimeError, "Not PREPARED"):
            UPGRADE.backup_mode({"phase": "BACKING_UP"}, False)

    def resume_fixture(self):
        state = self.root / "state"
        state.mkdir()
        saved_cron = b"original scheduled jobs\n"
        (state / "otobo.crontab").write_bytes(saved_cron)
        self.put(self.home, "RELEASE", b"VERSION = 11.1.0 beta2\n")
        with tarfile.open(state / "otobo-files.tar", "w") as archive:
            archive.add(self.home, arcname=self.home.name)
        info = {"phase": "BACKING_UP", "active_services": ["apache2.service"],
                "cron_present": True, "daemon_running": True, "db_name": "tessera",
                "tessera_package_sha256": hashlib.sha256(b"reviewed opm").hexdigest()}
        args = SimpleNamespace(db_name="tessera", services="apache2.service,cron.service")
        return state, info, args

    def test_backup_resume_preserves_original_startup_state(self):
        state, info, args = self.resume_fixture()
        original = json.dumps(info)
        cron_before = (state / "otobo.crontab").read_bytes()
        def stopped(argv, **kwargs):
            return SimpleNamespace(returncode=3 if argv[0] == "systemctl" else 1, stdout=b"")
        with patch.object(UPGRADE.subprocess, "run", side_effect=stopped):
            UPGRADE.validate_backup_resume(self.home, state, info, args, b"reviewed opm")
        self.assertEqual(json.dumps(info), original)
        self.assertEqual((state / "otobo.crontab").read_bytes(), cron_before)

    def test_backup_resume_rejects_active_writer(self):
        state, info, args = self.resume_fixture()
        with patch.object(UPGRADE.subprocess, "run",
                          return_value=SimpleNamespace(returncode=0, stdout=b"")):
            with self.assertRaisesRegex(RuntimeError, "writers stopped"):
                UPGRADE.validate_backup_resume(self.home, state, info, args, b"reviewed opm")

    def test_backup_resume_rejects_changed_package(self):
        state, info, args = self.resume_fixture()
        with self.assertRaisesRegex(RuntimeError, "original database"):
            UPGRADE.validate_backup_resume(self.home, state, info, args, b"different opm")

    def test_failed_database_dump_is_preserved_before_retry(self):
        state = self.root / "state"
        state.mkdir()
        (state / "database.sql.gz").write_bytes(b"failed original dump")
        UPGRADE.preserve_failed_dump(state)
        saved = list(state.glob("database.failed-*.sql.gz"))
        self.assertEqual(len(saved), 1)
        self.assertEqual(saved[0].read_bytes(), b"failed original dump")
        self.assertFalse((state / "database.sql.gz").exists())

    def test_system_table_error_is_detected_before_application_shutdown(self):
        state = self.root / "state"
        state.mkdir()
        stage = self.root / "source"
        stage.mkdir()
        self.put(self.home, "RELEASE", b"VERSION = 11.1.0 beta2\n")
        config = self.put(self.home, "Kernel/Config.pm", b"test configuration")
        with tarfile.open(state / "otobo-11.1.1-source.tar.gz", "w:gz"):
            pass
        info = {"phase": "PREPARED", "home": str(self.home), "stage": str(stage),
                "from": "11.1.0 beta2", "config_sha256": UPGRADE.digest(config),
                "opm_sha256": hashlib.sha256(b"installed").hexdigest()}
        (state / "state.json").write_text(json.dumps(info))
        args = SimpleNamespace(state=state, tessera_package=self.root / "package.opm",
            confirm_modules=True, db_name="tessera", db_defaults_file=None)
        def sql(argv, **kwargs):
            if "SHOW FUNCTION STATUS" in argv[-1]:
                raise UPGRADE.subprocess.CalledProcessError(1, argv, stderr=b"1558 mysql.proc")
            return SimpleNamespace(stdout=b"0")
        with patch.object(UPGRADE, "verify_archive"), \
             patch.object(UPGRADE, "package_export", return_value=b"installed"), \
             patch.object(UPGRADE, "audit", return_value=[]), \
             patch.object(UPGRADE, "compatibility_package", return_value=(b"merged", {}, [])), \
             patch.object(UPGRADE.shutil, "which", return_value="/bin/tool"), \
             patch.object(UPGRADE, "as_otobo", return_value=SimpleNamespace(stdout=b"tessera")), \
             patch.object(UPGRADE, "run", side_effect=sql), \
             patch.object(UPGRADE.subprocess, "run") as shutdown:
            with self.assertRaises(UPGRADE.subprocess.CalledProcessError):
                UPGRADE.apply(args)
            shutdown.assert_not_called()
        self.assertEqual(json.loads((state / "state.json").read_text())["phase"], "PREPARED")


if __name__ == "__main__":
    unittest.main()
