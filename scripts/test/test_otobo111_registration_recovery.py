import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "recover-otobo111-package-registration.py"
SPEC = importlib.util.spec_from_file_location("registration_recovery", SCRIPT)
RECOVERY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RECOVERY)

HARNESS = r'''
BEGIN {$INC{'Kernel/System/ObjectManager.pm'}=1}
our $Mode=$ARGV[1]||'empty';
our $FixtureOld;
our @Registry=$Mode eq 'existing' ? (['0.1.9','installed'])
    : $Mode eq 'target' ? (['0.1.10','installed']) : ();
{
package Kernel::System::ObjectManager;
sub new {bless {},shift}
sub Get {return bless {},$_[1] eq 'Kernel::System::DB' ? 'RecoveryDB' : 'RecoveryPackage'}
package RecoveryDB;
sub Connect {$_[0]}
sub begin_work {print STDERR "BEGIN\n";1}
sub commit {print STDERR "COMMIT\n";1}
sub rollback {print STDERR "ROLLBACK\n";1}
sub Prepare {
    my($S,%P)=@_;
    if ($P{SQL}=~/information_schema.statistics/) {
        $S->{Rows}=$main::Mode eq 'noindex' ? [] : [['source_article_id'],['article_delete']];
    }
    elsif ($P{SQL}=~/SELECT engine/) {$S->{Rows}=[[$main::Mode eq 'nontransactional' ? 'MyISAM' : 'InnoDB']]}
    elsif ($P{SQL}=~/SELECT version, install_status/) {$S->{Rows}=[@main::Registry]}
    else {die "Unexpected SQL in metadata recovery"}
    return 1;
}
sub FetchrowArray {my $R=shift @{$_[0]{Rows}};return $R ? @{$R} : ()}
sub Do {
    my($S,%P)=@_;
    die "Unexpected metadata write" if $P{SQL}!~/\AUPDATE package_repository SET install_status/;
    $main::Registry[0][1]='installed';print STDERR "STATUS\n";return 1;
}
package RecoveryPackage;
sub PackageParse {
    my($S,%P)=@_;$main::FixtureOld=$P{String};
    my($Name)=$main::FixtureOld=~m{<Name>(.*?)</Name>};
    my($Version)=$main::FixtureOld=~m{<Version>(.*?)</Version>};
    return (Name=>{Content=>$Name},Version=>{Content=>$Version});
}
sub RepositoryAdd {
    return 0 if $main::Mode eq 'addfail';
    @main::Registry=(['0.1.9','not installed']);print STDERR "ADD\n";return 1;
}
sub RepositoryGet {return $main::Mode eq 'corrupt' ? 'bad bytes' : $main::FixtureOld}
sub _RepositoryCacheClear {1}
sub AUTOLOAD {die "Unexpected package operation (hooks/install must never execute)"}
}
'''


class RegistrationRecovery(unittest.TestCase):
    def test_phase_guard_rejects_unrelated_recovery(self):
        with tempfile.TemporaryDirectory() as tmp:
            state = Path(tmp)
            (state / "state.json").write_text(json.dumps({"phase": "UPDATED_STOPPED"}))
            args = SimpleNamespace(migration_completed=True, state=state)
            with self.assertRaisesRegex(RuntimeError, "known package-registration"):
                RECOVERY.inputs(args)

    def test_completed_migration_evidence_required(self):
        with self.assertRaisesRegex(RuntimeError, "Migration finished"):
            RECOVERY.inputs(SimpleNamespace(migration_completed=False))

    def test_recovery_order_preserves_original_startup_state(self):
        with tempfile.TemporaryDirectory() as tmp:
            state = Path(tmp)
            home = state / "otobo"
            info = {"phase": "APPLYING", "active_services": ["apache2.service", "cron.service"],
                    "daemon_running": True, "cron_present": True}
            args = SimpleNamespace(services="apache2.service,cron.service")
            order = []
            with patch.object(RECOVERY, "inputs", return_value=(state, info, home, b"old", b"new", {}, [])), \
                 patch.object(RECOVERY.UPGRADE, "validate_backup_resume", side_effect=lambda *a: order.append("writers")), \
                 patch.object(RECOVERY.UPGRADE, "packet_preflight", side_effect=lambda *a: order.append("packet")), \
                 patch.object(RECOVERY, "restore_metadata", side_effect=lambda *a: order.append("metadata")), \
                 patch.object(RECOVERY.UPGRADE, "upgrade_packages", side_effect=lambda *a: order.append("upgrade")), \
                 patch.object(RECOVERY.UPGRADE, "finish_configuration", side_effect=lambda *a: order.append("configuration")), \
                 patch.object(RECOVERY.UPGRADE, "as_otobo") as native_migration:
                RECOVERY.recover(args)
                native_migration.assert_not_called()
            self.assertEqual(order, ["writers", "packet", "metadata", "upgrade", "configuration"])
            original = json.loads(next(state.glob("state.before-registration-*.json")).read_text())
            self.assertEqual(original["phase"], "APPLYING")
            self.assertEqual(info["active_services"], original["active_services"])
            self.assertTrue(info["cron_present"])
            self.assertTrue(info["daemon_running"])

    def perl(self, mode):
        old = "<otobo_package><Name>TESSERA-Base</Name><Version>0.1.9</Version><!-- café --></otobo_package>".encode()
        result = subprocess.run(["perl", "-e", HARNESS + RECOVERY.RESTORE_PROGRAM,
                                 hashlib.sha256(old).hexdigest(), mode], input=old, capture_output=True)
        result.stderr = result.stderr.replace(b"\r\n", b"\n")
        return result

    def test_missing_registry_restores_only_metadata_transactionally(self):
        result = self.perl("empty")
        self.assertEqual(result.returncode, 0, result.stderr.decode(errors="replace"))
        self.assertIn(b"ADD\nSTATUS\nCOMMIT", result.stderr)
        self.assertIn(b"no install or upgrade hooks", result.stdout)

    def test_existing_exact_original_registry_is_idempotent(self):
        result = self.perl("existing")
        self.assertEqual(result.returncode, 0, result.stderr.decode(errors="replace"))
        self.assertNotIn(b"ADD\n", result.stderr)
        self.assertIn(b"COMMIT", result.stderr)

    def test_target_or_partial_registry_is_not_overwritten(self):
        result = self.perl("target")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"unexpected or partially installed", result.stderr)
        self.assertIn(b"ROLLBACK", result.stderr)
        self.assertNotIn(b"ADD\n", result.stderr)

    def test_missing_native_schema_checkpoint_blocks_metadata_restore(self):
        result = self.perl("noindex")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"schema checkpoint is missing", result.stderr)
        self.assertNotIn(b"BEGIN\n", result.stderr)

    def test_failed_or_corrupt_restore_rolls_back(self):
        for mode in ("addfail", "corrupt"):
            with self.subTest(mode=mode):
                result = self.perl(mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(b"ROLLBACK", result.stderr)
                self.assertNotIn(b"COMMIT", result.stderr)

    def test_nontransactional_registry_blocks_restore(self):
        result = self.perl("nontransactional")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"requires transactional InnoDB", result.stderr)
        self.assertNotIn(b"BEGIN\n", result.stderr)


if __name__ == "__main__":
    unittest.main()
