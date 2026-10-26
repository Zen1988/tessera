"""Build inputs must survive the deliberately restricted Docker context allowlist."""
import fnmatch
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]


def included(name):
    allowed=True
    for rule in (ROOT/'.dockerignore').read_text(encoding='utf-8-sig').splitlines():
        rule=rule.strip()
        if not rule or rule.startswith('#'):
            continue
        negate=rule.startswith('!')
        pattern=rule[1:] if negate else rule
        if fnmatch.fnmatchcase(name,pattern.rstrip('/')) or (pattern.endswith('/') and name.startswith(pattern)):
            allowed=negate
    return allowed


class BuildContextTests(unittest.TestCase):
    def test_docker_copy_sources_exist_and_are_admitted(self):
        for line in (ROOT/'Dockerfile').read_text().splitlines():
            if not line.startswith('COPY ') or '--from=' in line:
                continue
            for source in line.split()[1:-1]:
                with self.subTest(source=source):
                    self.assertTrue((ROOT/source).exists())
                    self.assertTrue(included(source),source+' excluded from build context')
    def test_every_python_test_is_admitted(self):
        tests=list((ROOT/'tests').glob('test_*.py'))
        self.assertGreaterEqual(len(tests),7)
        for source in tests:
            self.assertTrue(included(source.relative_to(ROOT).as_posix()),source.name)
    def test_private_and_generated_files_stay_excluded(self):
        for name in ('dist/image.tar','private.key','credentials.json','.env','__pycache__/monitor.pyc'):
            self.assertFalse(included(name),name)
