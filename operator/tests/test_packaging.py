"""Regression for Linux scripts packaged from Windows working trees."""
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import package as kit


class PackagingTests(unittest.TestCase):
    def build_fixture(self,payload):
        directory=tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        root=Path(directory.name)
        (root/'build.sh').write_bytes(payload)
        (root/'note.txt').write_bytes(b'preserve\r\n')
        output=root/'out'/'kit.zip'
        with patch.object(kit,'files',['build.sh','note.txt']):
            kit.package(output,root)
        return output

    def test_crlf_bom_normalized_and_executable(self):
        output=self.build_fixture(b'\xef\xbb\xbf#!/usr/bin/env sh\r\nset -eu\r\necho ok\r\n')
        with zipfile.ZipFile(output) as archive:
            entry=archive.getinfo(f'tessera-operator-{kit.VERSION}/build.sh')
            self.assertEqual(archive.read(entry),b'#!/usr/bin/env sh\nset -eu\necho ok\n')
            self.assertEqual((entry.external_attr>>16)&0o777,0o755)
            self.assertEqual(archive.read(f'tessera-operator-{kit.VERSION}/note.txt'),b'preserve\r\n')
        self.assertTrue(output.with_suffix('.zip.sha256').read_text().startswith(hashlib.sha256(output.read_bytes()).hexdigest()))

    def test_existing_lf_is_preserved(self):
        script=b'#!/bin/sh\nset -eu\nprintf "%s\\n" ok\n'
        output=self.build_fixture(script)
        with zipfile.ZipFile(output) as archive:
            self.assertEqual(archive.read(f'tessera-operator-{kit.VERSION}/build.sh'),script)

    def test_missing_shebang_rejected(self):
        with self.assertRaisesRegex(ValueError,'shebang'):
            self.build_fixture(b'set -eu\r\n')
