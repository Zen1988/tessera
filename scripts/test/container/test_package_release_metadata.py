import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('package_builder', ROOT / 'scripts/build_opm.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)

class PackageReleaseMetadataTest(unittest.TestCase):
    def fixture(self, root, descriptor):
        path = root / 'var/governancedb/container_release.json'
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps(descriptor))
        sopm = root / 'package.sopm'
        sopm.write_text('<otobo_package><Name>TESSERA-Base</Name><Version>0.0.194</Version><Filelist><File Location="var/governancedb/container_release.json" Permission="660"/></Filelist></otobo_package>')
        return sopm, root / 'release.opm'

    def test_stale_descriptor_blocks_release_before_output(self):
        with tempfile.TemporaryDirectory() as d:
            sopm, output = self.fixture(Path(d), {'package':'TESSERA-Base','version':'0.0.188','upgrade_from':['0.0.180']})
            with self.assertRaisesRegex(ValueError, 'must match SOPM'):
                builder.build(sopm, output)
            self.assertFalse(output.exists())

    def test_matching_descriptor_builds_and_is_byte_exact(self):
        import base64
        import xml.etree.ElementTree as ET
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            sopm, output = self.fixture(root, {'package':'TESSERA-Base','version':'0.0.194','upgrade_from':['0.0.188','0.0.193']})
            self.assertEqual(builder.build(sopm, output), 1)
            file = ET.parse(output).find('./Filelist/File')
            self.assertEqual(base64.b64decode(file.text), (root/file.get('Location')).read_bytes())

    def test_invalid_upgrade_origin_cannot_be_published(self):
        for origins in (['0.0.194'], ['0.0.195'], ['0.0.193','0.0.193'], ['bad'], []):
            with self.subTest(origins=origins), tempfile.TemporaryDirectory() as d:
                sopm, output = self.fixture(Path(d), {'package':'TESSERA-Base','version':'0.0.194','upgrade_from':origins})
                with self.assertRaises(ValueError):
                    builder.build(sopm, output)
                self.assertFalse(output.exists())

    def test_current_package_passes_real_toolkit_bundle_checks(self):
        import base64
        import xml.etree.ElementTree as ET
        from unittest.mock import patch
        spec = importlib.util.spec_from_file_location('toolkit_release', ROOT / 'container/ubuntu2604/scripts/release.py')
        release = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(release)
        current = ET.parse(ROOT / 'Kernel/Package/GovernanceDB/TESSERA-Base.sopm').findtext('Version')
        package = (ROOT / f'Kernel/Package/TESSERA-Base-{current}.opm').read_bytes()
        with tempfile.TemporaryDirectory() as d:
            source, output = Path(d)/'source', Path(d)/'bundle/release.json'
            output.parent.mkdir()
            for entry in ET.fromstring(package).findall('./Filelist/File'):
                path = source/entry.get('Location')
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(base64.b64decode(entry.text))
            def export(*args, **kwargs):
                (output.parent/'package.opm').write_bytes(package)
            with patch.object(release.subprocess, 'run', side_effect=export):
                result = release.upgrade_bundle(source, current, output)
            self.assertIn('0.0.193', result['upgrade_from'])
            self.assertEqual(len(result['package_sha256']), 64)

if __name__ == '__main__':
    unittest.main()
