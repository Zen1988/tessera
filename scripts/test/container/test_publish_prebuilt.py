import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("publish_prebuilt", ROOT / "scripts/publish_prebuilt_oci.py")
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

class Layout(unittest.TestCase):
    def exercise(self, bad=None):
        original = b'{"schemaVersion":2,"manifests":[]}'
        sha = hashlib.sha256(original).hexdigest()
        index = {"manifests":[{"digest":"sha256:"+sha,"annotations":{"org.opencontainers.image.ref.name":m.IMAGE_TAG}}]}
        entries = [("index.json", json.dumps(index).encode()), ("oci-layout", b'{}'), ("blobs/sha256/"+sha, original)]
        if bad == "path": entries.append(("../escape", b"bad"))
        if bad == "duplicate": entries.append(entries[0])
        if bad == "digest": entries[-1] = (entries[-1][0], b"changed")
        if bad == "symlink": entries.append(("link", None))
        with tempfile.TemporaryDirectory() as temp:
            archive = Path(temp)/"image.tar.gz"
            with tarfile.open(archive,"w:gz") as t:
                for name,data in entries:
                    info=tarfile.TarInfo(name)
                    if data is None:
                        info.type=tarfile.SYMTYPE;info.linkname="/etc/passwd";t.addfile(info)
                    else:
                        info.size=len(data);t.addfile(info,io.BytesIO(data))
            with patch.object(m,"IMAGE_DIGEST","sha256:"+sha):
                if bad:
                    with self.assertRaises(ValueError):m.prepare_layout(archive,Path(temp)/"layout")
                else:
                    output=m.prepare_layout(archive,Path(temp)/"layout")
                    self.assertEqual((output/"blobs/sha256"/sha).read_bytes(),original)
    def test_valid_layout_preserves_original_index(self):self.exercise()
    def test_rejects_unexpected_paths_links_duplicates_and_bad_digests(self):
        for mode in ("path","symlink","duplicate","digest"):
            with self.subTest(mode=mode):self.exercise(mode)

if __name__=="__main__":unittest.main()
