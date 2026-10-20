"""Fixture checks for staging's embedded Python; no sudo/rsync/host access."""
import contextlib
import io
import os
from pathlib import Path
import re
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT/'scripts/container/stage-host-app.sh'
BLOCKS = re.findall(r"<<'PY'\n(.*?)\nPY", SCRIPT.read_text(), re.S)
OPM = ROOT/'Kernel/Package/TESSERA-Base-0.0.180.opm'
CORE = ROOT/'Kernel/System/Cache/Redis.pm'

def run_block(number, *args):
    previous = sys.argv
    try:
        sys.argv = ['embedded', *map(str,args)]
        with contextlib.redirect_stdout(io.StringIO()):
            exec(compile(BLOCKS[number], 'stage-embedded-python', 'exec'), {'__name__':'__main__'})
    finally:
        sys.argv = previous

class HostStageTest(unittest.TestCase):
    def test_reference_identity(self):
        self.assertEqual(len(BLOCKS), 2)
        run_block(0, OPM, CORE)

    def test_wrong_reference_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            bad = Path(d)/'Redis.pm'
            bad.write_text('fixture')
            with self.assertRaises(SystemExit): run_block(0, OPM, bad)

    def test_restore_actual_release(self):
        with tempfile.TemporaryDirectory() as d:
            stage = Path(d)/'app'
            stage.mkdir()
            run_block(1, stage, OPM, CORE)
            self.assertEqual((stage/'Kernel/System/Cache/Redis.pm').read_bytes(), CORE.read_bytes())
            self.assertTrue((stage/'Custom/Kernel/System/Cache/Redis.pm').is_file())
            self.assertTrue((stage/'var/governancedb/runtime_overlay/Kernel/Modules/CustomerTicketZTSMAction.pm').is_file())
            self.assertFalse((stage/'Kernel/Config.pm').exists())
            self.assertTrue((Path(d)/'app.inventory.json').is_file())

    def test_private_key_rejected_without_value_in_error(self):
        with tempfile.TemporaryDirectory() as d:
            stage = Path(d)/'app'
            stage.mkdir()
            (stage/'integration.conf').write_text('-----BEGIN PRIVATE KEY-----\nfixture-private-content')
            with self.assertRaises(SystemExit) as result: run_block(1, stage, OPM, CORE)
            self.assertNotIn('fixture-private-content', str(result.exception))

    def test_config_pm_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            stage = Path(d)/'app'
            (stage/'Kernel').mkdir(parents=True)
            (stage/'Kernel/Config.pm').write_text('fixture-config')
            with self.assertRaises(SystemExit): run_block(1, stage, OPM, CORE)

    @unittest.skipIf(os.name == 'nt', 'Unix symlink fixture')
    def test_external_symlink_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            stage = Path(d)/'app'
            stage.mkdir()
            (stage/'external').symlink_to('/etc')
            with self.assertRaises(SystemExit): run_block(1, stage, OPM, CORE)

if __name__ == '__main__': unittest.main()
