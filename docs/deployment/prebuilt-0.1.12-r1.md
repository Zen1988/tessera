# Prebuilt TESSERA0.1.12-r1 image

Owner-supplied build: Linux amd64, Ubuntu26.04, system Perl5.40.1,
latest dependency policy, successful build receipt2026-11-24.

Original OCI index digest:
sha256:c0b2e74863ae4999cec60147f4a9e47ead93880726535543999e09bf765db376

Image archive SHA256:
aaf9502ed06229b073d46383ea986343ef42056b112951a9a8255b18300045be

Matching upgrade bundle SHA256:
c498b25b73ccb53459e0c31580f496c5e37c7d3220c6f25501dc63d755bd573a

The0.1.12 GitHub release contains tessera-image.tar.gz,
tessera-upgrade-bundle.tar.gz, companion checksum files and the static scan report.
These archives are release assets, not Git blobs. The provided Build directory
contains the source context and is not bulk-committed into the repository.

The publish-prebuilt Actions workflow transfers that checksum-pinned image to
GitHub Packages using the repository-scoped GITHUB_TOKEN with packages:write.
It preserves the original OCI manifests, layers and provenance, verifies the
registry digest afterward and does not rebuild or alter application files.
The intended reference is ghcr.io/zen1988/tessera:0.1.12-r1-ubuntu26.04.
Publication workflow45351264198 succeeded; anonymous pull verified the exact original digest.
The package is publicly pullable.

Once published, pull using the immutable digest:

```bash
docker pull ghcr.io/zen1988/tessera@sha256:c0b2e74863ae4999cec60147f4a9e47ead93880726535543999e09bf765db376
```

Use the matching upgrade bundle and existing controlled release workflow for an
upgrade. Pulling/changing an image does not migrate a database. Existing healthy
0.1.12 deployments do not need incident recovery replay.

Static publication scan covered6303 source files and45654 image-layer files.
No deployment Config.pm, credential-directory files or recognized GitHub/AWS
token patterns were found. Key-format matches were in system crypto libraries,
public Crypt-JWT/CryptX documentation and the public Mojo development key fixture.
Mojo/Perl documentation bytes matched public upstream sources. This is not a
full vulnerability assessment or a local runtime integration test; Docker Linux
Engine was unavailable. The build receipt is supplied by the owner's build host.
