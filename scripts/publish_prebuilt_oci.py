"""Publish the reviewed 0.1.12-r1 build without rebuilding or altering its digest."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile
import urllib.request

ARCHIVE_SHA = "aaf9502ed06229b073d46383ea986343ef42056b112951a9a8255b18300045be"
IMAGE_DIGEST = "sha256:c0b2e74863ae4999cec60147f4a9e47ead93880726535543999e09bf765db376"
IMAGE_TAG = "0.1.12-r1-ubuntu26.04"
ARCHIVE_URL = "https://github.com/Zen1988/tessera/releases/download/0.1.12/tessera-image.tar.gz"


def prepare_layout(archive, destination):
    """Extract only reviewed regular OCI metadata/blobs and validate all digests."""
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=False)
    seen = set()
    with tarfile.open(archive, "r:gz") as stream:
        for member in stream:
            if member.isdir() and member.name in ("blobs", "blobs/sha256"):
                continue
            if not member.isfile() or member.name in seen:
                raise ValueError("Nonregular or duplicate archive member")
            if member.name not in ("index.json", "manifest.json", "oci-layout") and not re.fullmatch(r"blobs/sha256/[0-9a-f]{64}", member.name):
                raise ValueError("Unexpected archive path")
            seen.add(member.name)
            target = destination / member.name
            target.parent.mkdir(parents=True, exist_ok=True)
            digest = hashlib.sha256()
            with stream.extractfile(member) as incoming, target.open("xb") as outgoing:
                for chunk in iter(lambda: incoming.read(1048576), b""):
                    digest.update(chunk)
                    outgoing.write(chunk)
            if member.name.startswith("blobs/") and digest.hexdigest() != target.name:
                raise ValueError("OCI blob digest mismatch")
    index = json.loads((destination / "index.json").read_text())
    if len(index["manifests"]) != 1 or index["manifests"][0]["digest"] != IMAGE_DIGEST:
        raise ValueError("Unexpected exported image")
    descriptor = index["manifests"][0]
    if descriptor.get("annotations", {}).get("org.opencontainers.image.ref.name") != IMAGE_TAG:
        raise ValueError("Unexpected image tag")
    # The export index references the original image index, including provenance.
    original = destination / "blobs/sha256" / IMAGE_DIGEST.split(":")[1]
    if hashlib.sha256(original.read_bytes()).hexdigest() != IMAGE_DIGEST.split(":")[1]:
        raise ValueError("Original image index missing or mismatched")
    return destination


def main():
    if os.environ.get("GITHUB_REPOSITORY") != "Zen1988/tessera":
        raise SystemExit("Only the reviewed repository may publish this image")
    token = os.environ["GITHUB_TOKEN"]
    actor = os.environ["GITHUB_ACTOR"]
    reference = "ghcr.io/zen1988/tessera:" + IMAGE_TAG
    with tempfile.TemporaryDirectory(prefix="tessera-publish-") as temporary:
        root = Path(temporary)
        archive = root / "image.tar.gz"
        digest = hashlib.sha256()
        with urllib.request.urlopen(ARCHIVE_URL, timeout=120) as incoming, archive.open("xb") as outgoing:
            for chunk in iter(lambda: incoming.read(1048576), b""):
                digest.update(chunk)
                outgoing.write(chunk)
        if digest.hexdigest() != ARCHIVE_SHA:
            raise ValueError("Release image archive checksum mismatch")
        layout = prepare_layout(archive, root / "layout")
        auth = root / "auth.json"
        subprocess.run(["skopeo", "login", "--authfile", str(auth), "--username", actor,
                        "--password-stdin", "ghcr.io"], input=token.encode(), check=True)
        subprocess.run(["skopeo", "copy", "--authfile", str(auth), "--all", "--preserve-digests",
                        "oci:" + str(layout) + ":" + IMAGE_TAG, "docker://" + reference], check=True)
        raw = subprocess.run(["skopeo", "inspect", "--authfile", str(auth), "--raw",
                              "docker://" + reference], capture_output=True, check=True).stdout
        if "sha256:" + hashlib.sha256(raw).hexdigest() != IMAGE_DIGEST:
            raise ValueError("Published registry digest differs")
        receipt = {"reference": reference, "digest": IMAGE_DIGEST, "archive_sha256": ARCHIVE_SHA}
        print(json.dumps(receipt, indent=2))
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as summary:
            summary.write("Published `" + reference + "` with original digest `" + IMAGE_DIGEST + "`.\n")


if __name__ == "__main__":
    main()
