import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location(
    "redis_diagnostic", ROOT / "container/ubuntu2604/scripts/diagnose-redis.py")
D = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(D)

FIXTURE = r'''
package Kernel::System::ObjectManager;
sub new {bless {},shift}
sub Get {
    my ($Self,$Name)=@_;
    return bless {},'FixtureConfig' if $Name eq 'Kernel::Config';
    return bless {},'FixtureBackend' if $Name eq 'Kernel::System::Cache::Redis';
    return bless {},'FixtureDB' if $Name eq 'Kernel::System::DB';
    return $Self;
}
sub Require {1}
package FixtureConfig;
sub Get {
    return 'Kernel::System::Cache::Redis' if $_[1] eq 'Cache::Module';
    return {PasswordSecret=>'password',Server=>'fixture:6379',DatabaseNumber=>0};
}
package Redis;
our %Values;
sub new {bless {},shift}
sub ping {die "WRONGPASS private-secret-123\n" if $ENV{DIAGNOSTIC_FIXTURE} eq 'auth';1}
sub select {1}
sub info {{role=>$ENV{DIAGNOSTIC_FIXTURE} eq 'readonly'?'slave':'master'}}
sub set {die "READONLY private-secret-123\n" if $ENV{DIAGNOSTIC_FIXTURE} eq 'readonly';$Values{$_[1]}=$_[2];1}
sub get {$Values{$_[1]}}
sub sadd {die "NOPERM private-secret-123\n" if $ENV{DIAGNOSTIC_FIXTURE} eq 'acl';1}
sub expire {1}
sub del {1}
sub srem {1}
package FixtureBackend;
sub Set {die "serialization private-secret-123\n" if $ENV{DIAGNOSTIC_FIXTURE} eq 'backend';1}
sub Get {'nonsecret-probe'}
sub Delete {1}
package FixtureDB;
sub Prepare {$_[0]{row}=1;1}
sub FetchrowArray {return () if !delete $_[0]{row};return (1)}
1;
'''


class RedisDiagnostic(unittest.TestCase):
    def run_probe(self, mode):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            path = root / "Kernel/System/ObjectManager.pm"
            path.parent.mkdir(parents=True)
            path.write_text(FIXTURE)
            path = root / "Kernel/System/TESSERA/Secrets.pm"
            path.parent.mkdir()
            path.write_text("package Kernel::System::TESSERA::Secrets; sub Read {'private-secret-123'};1;")
            script = root / "probe.pl"
            script.write_text(D.PERL)
            result = subprocess.run(["perl", "-I" + str(root), str(script)],
                                    capture_output=True, text=True,
                                    env=dict(os.environ, DIAGNOSTIC_FIXTURE=mode))
            self.assertNotIn("private-secret-123", result.stdout + result.stderr)
            return result

    def test_full_success_with_existing_setting(self):
        result = self.run_probe("success")
        self.assertEqual(result.returncode, 0, result.stderr)
        for value in ("redis_role=master", "redis_set_ex=ok", "redis_sadd=ok",
                      "cache_set_roundtrip=ok", "sysconfig_change_setting_rows=1",
                      "completed-no-upgrade-no-journal-change"):
            self.assertIn(value, result.stdout)

    def test_auth_failure_redacted_and_no_probe_writes(self):
        result = self.run_probe("auth")
        self.assertEqual(result.returncode, 1)
        self.assertIn("redis_connect_auth_select=WRONGPASS", result.stdout)
        self.assertNotIn("redis_set_ex=", result.stdout)

    def test_replica_and_acl_failure_classes(self):
        result = self.run_probe("readonly")
        self.assertIn("redis_role=slave", result.stdout)
        self.assertIn("redis_set_ex=READONLY", result.stdout)
        result = self.run_probe("acl")
        self.assertIn("redis_sadd=NOPERM", result.stdout)

    def test_backend_failure_does_not_print_exception(self):
        result = self.run_probe("backend")
        self.assertIn("redis_set_ex=ok", result.stdout)
        self.assertIn("cache_set_roundtrip=operation-error", result.stdout)

    def test_cloned_job_runs_probe_and_preserves_original(self):
        module = D.load_diagnostic()
        original = {"status": {"conditions": [{"type": "Failed", "status": "True"}]},
                    "spec": {"template": {"metadata": {"labels": {"job-name": "old"}},
                    "spec": {"containers": [{"name": "upgrade", "image": "fixture:0.1.12",
                             "args": ["upgrade"], "env": [{"name": "TESSERA_UPGRADE_QUIESCED", "value": "1"}]}],
                             "initContainers": [{"name": "stage-upgrade"}]}}}}
        result = module.diagnostic_job(original, "tessera", "diagnostic")
        container = result["spec"]["template"]["spec"]["containers"][0]
        self.assertEqual(container["args"], [D.PERL])
        self.assertEqual(container["image"], "fixture:0.1.12")
        self.assertEqual(container["env"], [])
        self.assertEqual(original["spec"]["template"]["spec"]["containers"][0]["args"], ["upgrade"])


if __name__ == "__main__":
    unittest.main()
