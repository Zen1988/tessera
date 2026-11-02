import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('build_opm', ROOT / 'scripts/build_opm.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class Layout(unittest.TestCase):
    def test_new_top_level_document_root_rejected(self):
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            base = Path(temp)
            source = base / 'package.sopm'
            for location in ['docs/example.md', 'examples/test.yml', '../escape']:
                source.write_text('<otobo_package><Name>TESSERA-Base</Name><Version>0.0.184</Version><Filelist><File Location="' + location + '" Permission="660"/></Filelist></otobo_package>')
                with self.assertRaises(ValueError): builder.build(source, base / 'out.opm')

    def test_existing_var_parent_is_packaged(self):
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            base = Path(temp)
            target = base / 'var/tessera/docs/example.md'
            target.parent.mkdir(parents=True)
            target.write_text('test')
            source = base / 'package.sopm'
            source.write_text('<otobo_package><Name>TESSERA-Base</Name><Version>0.0.184</Version><Filelist><File Location="var/tessera/docs/example.md" Permission="660"/></Filelist></otobo_package>')
            self.assertEqual(builder.build(source, base / 'out.opm'), 1)


if __name__ == '__main__': unittest.main()
