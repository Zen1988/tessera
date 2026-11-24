"""Execute the recovery program against isolated Perl DB/package fixtures."""
import hashlib
import base64
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "container/ubuntu2604/image/recover-release012.pl"
LABEL_SHA = "8546fd85ffd059aadd48afaf8a2c5a0987017c6da6558685eb5ec6d17ae328f9"
BASE_SHA = "7911eff6b39b594f95d036386caab604356120945413a0fe2650c3ec35352aff"
OLD_SHA = "9c9a4554d098204190ebc3b22d51348756b342e9021655e089e9b3ee4093ea55"

FIXTURE = r'''
package Fixture;
use JSON::PP ();
our ($Recovery,$Deleted,$Repair,$Reconcile,$Configured);
our $Base=$ENV{RECOVERY_CASE} eq 'wrong-base'?'0.1.9':'0.1.8';
our $State=JSON::PP->new->canonical->encode({phase=>'UPGRADING',version=>'0.1.12',from=>'0.1.8',hash=>$ENV{NEW_HASH},owner=>'old'});
our $Journal=JSON::PP->new->canonical->encode({phase=>'UPGRADING',version=>'11.1.1',hash=>$ENV{LABEL_HASH}});
our $JournalPresent=1;
BEGIN {
    *CORE::GLOBAL::system=sub {
        return 1 if $ENV{RECOVERY_CASE} eq 'dependency-fail';
        return 1 if $ENV{RECOVERY_CASE} eq 'configure-fail' && grep {/configure\.py/} @_;
        return 0;
    };
}
package Kernel::System::ObjectManager;
sub new {bless {},shift}
sub Get {
    my ($S,$N)=@_;
    return bless {},'FixtureDB' if $N eq 'Kernel::System::DB';
    return bless {},'FixtureGate' if $N eq 'Kernel::System::TESSERA::ReleaseUpgrade';
    return bless {},'FixturePackage' if $N eq 'Kernel::System::TESSERA::ReleasePackage';
    return $S;
}
sub Configure {$Fixture::Configured++}
sub GenerateRandomString {'r'x40}
sub Require {1}
sub Run {$ENV{RECOVERY_CASE} eq 'cache-cleanup-fail'?1:0}
sub Create {bless {},'FixtureTask'}
sub _OTOBO111CompatibilityPreflight {1}
sub _OTOBO111AddonPreflight {1}
package FixtureTask;
sub Run {
    return 0 if $ENV{RECOVERY_CASE} eq 'framework-fail';
    $Fixture::State='changed-owner' if $ENV{RECOVERY_CASE} eq 'owner-fail';
    return 1;
}
package FixtureDB;
sub Connect {$_[0]}
sub Prepare {
    my ($S,%P)=@_;
    my @R;
    if ($P{SQL}=~/LIKE 'TESSERA::PackageUpgrade/) {
        @R=(['TESSERA::PackageUpgrade::ITSMConfigItemLabelPrint',$Fixture::Journal]) if $Fixture::JournalPresent;
        push @R,['unexpected','{}'] if $ENV{RECOVERY_CASE} eq 'extra-journal';
    } elsif ($P{SQL}=~/SELECT id FROM/) {@R=([42])}
    elsif ($P{SQL}=~/SELECT name,version/) {
        @R=(['ITSMConfigItemLabelPrint','11.1.1']);
        push @R,['unexpected','1.0.0'] if $ENV{RECOVERY_CASE} eq 'extra-package';
    }
    elsif ($P{SQL}=~/max_allowed_packet/) {@R=([$ENV{RECOVERY_CASE} eq 'small-packet'?16777216:134217728])}
    elsif ($P{SQL}=~/SELECT data_key/) {@R=(['existing']) if $ENV{RECOVERY_CASE} eq 'already-attempted'}
    elsif ($P{SQL}!~/SELECT request_data/) {die "Unexpected test SQL"}
    $S->{Rows}=\@R;
    return 1;
}
sub FetchrowArray {my $R=shift @{$_[0]{Rows}};return $R?@$R:()}
sub do {
    my ($S,$SQL,$Attr,@P)=@_;
    if ($SQL=~/^INSERT/) {$Fixture::Recovery=$P[1];return 1}
    if ($SQL=~/^UPDATE/) {$Fixture::Recovery=$P[0];return 1}
    if ($SQL=~/^DELETE/) {
        die "Journal cleared before repair" if !$Fixture::Repair;
        return 0 if $ENV{RECOVERY_CASE} eq 'journal-race';
        die "Wrong journal CAS" if $P[1] ne $Fixture::Journal;
        $Fixture::JournalPresent=0;$Fixture::Deleted++;return 1;
    }
    die "Unexpected write";
}
package FixtureGate;
sub _Read {$Fixture::State}
sub _Decode {JSON::PP->new->decode($_[1])}
sub _Encode {JSON::PP->new->canonical->encode($_[1])}
sub _Version {$Fixture::Base}
sub _InstalledHash {$_[1] eq '0.1.8'?$ENV{OLD_HASH}:$ENV{NEW_HASH}}
sub _Write {
    my ($S,$Before,$After)=@_;
    die "Wrong release CAS" if $Before ne $Fixture::State;
    $Fixture::State=$After;return $After;
}
sub Check {
    die "Not READY" if JSON::PP->new->decode($Fixture::State)->{phase} ne 'READY';
    return 1;
}
package FixturePackage;
sub PackageParse {
    my %P=(Name=>{Content=>'ITSMConfigItemLabelPrint'},Version=>{Content=>'11.1.1'},
        Filelist=>[{Location=>'label.txt',Content=>'expected-label-bytes',Encode=>''}]);
    $P{CodeUpgrade}=[{Content=>'unreviewed'}] if $ENV{RECOVERY_CASE} eq 'hooked-label';
    return %P;
}
sub PackageReinstall {
    die "Caching not disabled" if !$Fixture::Configured;
    $Fixture::Repair++;
    return 0 if $ENV{RECOVERY_CASE} eq 'repair-fail';
    open my $F,'>:raw',"$ENV{APP_ROOT}/label.txt" or die $!;
    print {$F} $ENV{RECOVERY_CASE} eq 'file-fail'?'wrong':'expected-label-bytes';
    close $F;return 1;
}
END {
    my $Phase=eval {JSON::PP->new->decode($Fixture::State)->{phase}} || 'changed';
    print "FIXTURE=",JSON::PP->new->canonical->encode({
        journal=>$Fixture::JournalPresent?1:0,deleted=>$Fixture::Deleted||0,
        repaired=>$Fixture::Repair||0,reconciled=>$Fixture::Reconcile||0,
        recovery=>$Fixture::Recovery?1:0,phase=>$Phase}),"\n";
}
1;
'''


class RecoveryProgram(unittest.TestCase):
    def exercise(self, mode):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            app, recovery, library = [root / n for n in ("app", "recovery", "library")]
            for p in (app / "Kernel/System", app / "scripts", recovery, library,
                      root / "include/Kernel/System", root / "opt/tessera/dependencies",
                      root / "opt/tessera/upgrade-bundle/packages"):
                p.mkdir(parents=True, exist_ok=True)
            (root / "include/Kernel/System/ObjectManager.pm").write_text(FIXTURE)
            (app / "Kernel/Config.pm").write_text("unchanged-private-config")
            framework_file = app / "scripts/Fixture.pm"
            framework_file.write_text("framework-fixture")
            framework = {"tasks": ["Fixture", "RemoveRedisOverride"], "files": {
                "scripts/Fixture.pm": hashlib.sha256(framework_file.read_bytes()).hexdigest()}}
            if mode == "framework-source-fail":
                framework_file.write_text("changed-framework")
            (recovery / "framework-11.1.1.json").write_text(json.dumps(framework))
            (recovery / "upgrade-cache.pl").write_bytes(
                (ROOT / "container/ubuntu2604/image/upgrade-cache.pl").read_bytes())
            (library / "package-inventory.pl").write_text(
                "sub InstalledArtifactHash {$ENV{LABEL_HASH}} sub CheckInventory {1} 1;")
            (library / "package-reconcile.pl").write_text(
                "sub ReconcilePackages {die 'Journal still present' if $Fixture::JournalPresent;"
                "$Fixture::Reconcile++;$Fixture::Base='0.1.12';1} 1;")
            meta = {"version": "0.1.12", "package_sha256": BASE_SHA, "upgrade_from": ["0.1.8"]}
            inventory = {"packages": [{"name": "ITSMConfigItemLabelPrint", "version": "11.1.1",
                                       "package_sha256": LABEL_SHA}]}
            for prefix in ("opt/tessera/dependencies", "opt/tessera/upgrade-bundle"):
                (root / prefix / "release.json").write_text(json.dumps(meta))
                (root / prefix / "package-modules.json").write_text(json.dumps(inventory))
            with zipfile.ZipFile(ROOT / "outputs/TESSERA-0.1.12-OTOBO-11.1.1-Addon-Continuation.zip") as z:
                (root / "opt/tessera/upgrade-bundle/packages" / (LABEL_SHA + ".opm")).write_bytes(
                    z.read("ITSMConfigItemLabelPrint-11.1.1.opm"))
            source = SOURCE.read_text().replace("/opt/tessera-release012-recovery", recovery.as_posix())
            source = source.replace("/usr/local/lib/tessera", library.as_posix())
            source = source.replace("/opt/otobo", app.as_posix()).replace("/opt/tessera", (root / "opt/tessera").as_posix())
            script = root / "recover.pl"
            script.write_text(source)
            control = "require '" + script.as_posix() + "';"
            encoded = base64.b64encode(control.encode()).decode()
            result = subprocess.run(["perl", "-I" + str(root / "include"), "-MMIME::Base64", "-e",
                "eval decode_base64($ARGV[0]); die $@ if $@;", encoded],
                capture_output=True, text=True, env=dict(os.environ, RECOVERY_CASE=mode,
                TESSERA_UPGRADE_QUIESCED="1", TESSERA_TEST_NO_BACKUP="1",
                TESSERA_RECOVERY_CHECK_ONLY="1" if mode=="preflight-only" else "0",
                APP_ROOT=str(app), OLD_HASH=OLD_SHA, NEW_HASH=BASE_SHA, LABEL_HASH=LABEL_SHA))
            self.assertNotIn("unchanged-private-config", result.stdout + result.stderr)
            lines = [x for x in result.stdout.splitlines() if x.startswith("FIXTURE=")]
            self.assertEqual(len(lines), 1, result.stderr)
            return result, json.loads(lines[0][8:])

    def test_success_orders_repair_journal_completion_and_ready(self):
        result, state = self.exercise("success")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(state, {"journal": 0, "deleted": 1, "repaired": 1,
                                "reconciled": 1, "recovery": 1, "phase": "READY"})
        self.assertLess(result.stdout.index("LABELPRINT_VERIFIED"), result.stdout.index("RECONCILING"))

    def test_release_guard_reports_each_match_without_exposing_receipt(self):
        result, state = self.exercise("wrong-base")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("release_check=installed_base;match=no", result.stdout)
        self.assertIn("release_check=receipt_hash;match=yes", result.stdout)
        self.assertEqual(result.stdout.count("release_check="), 6)
        self.assertNotIn(BASE_SHA, result.stdout)
        self.assertEqual(state["recovery"], 0)

    def test_extracted_bundle_contains_package_plan_dependencies(self):
        import importlib.util
        with tempfile.TemporaryDirectory(dir=ROOT / ".artifacts") as directory:
            with zipfile.ZipFile(ROOT / "outputs/TESSERA-0.1.12-LabelPrint-Recovery-r2.zip") as z:
                z.extractall(directory)
            path = Path(directory) / "scripts/diagnose-release.py"
            spec = importlib.util.spec_from_file_location("extracted_release012_diagnostic", path)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            self.assertIn("sub InstalledArtifactHash", module.diagnostic_program(True))
            self.assertIn("sub ReconcilePackages", module.diagnostic_program(True))

    def test_preflight_failures_have_no_writes(self):
        for mode in ("wrong-base", "extra-journal", "extra-package", "small-packet", "already-attempted",
                     "hooked-label", "framework-source-fail", "dependency-fail"):
            with self.subTest(mode=mode):
                result, state = self.exercise(mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(state["recovery"], 0)
                self.assertEqual(state["journal"], 1)
                self.assertEqual(state["reconciled"], 0)

    def test_check_only_performs_no_migration_or_receipt_write(self):
        result, state = self.exercise("preflight-only")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("preflight=ok", result.stdout)
        self.assertEqual(state["recovery"], 0)
        self.assertEqual(state["journal"], 1)
        self.assertEqual(state["repaired"], 0)
        self.assertEqual(state["reconciled"], 0)

    def test_unfinished_repairs_never_clear_journal_or_reconcile(self):
        for mode in ("framework-fail", "owner-fail", "repair-fail", "file-fail", "journal-race"):
            with self.subTest(mode=mode):
                result, state = self.exercise(mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(state["journal"], 1)
                self.assertEqual(state["recovery"], 1)
                self.assertEqual(state["reconciled"], 0)
                self.assertNotEqual(state["phase"], "READY")

    def test_config_failure_keeps_release_blocked_after_verified_repair(self):
        for mode in ("configure-fail", "cache-cleanup-fail"):
            with self.subTest(mode=mode):
                result, state = self.exercise(mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(state["journal"], 0)
                self.assertEqual(state["phase"], "CONFIGURING")
                self.assertEqual(state["recovery"], 1)


if __name__ == "__main__":
    unittest.main()
