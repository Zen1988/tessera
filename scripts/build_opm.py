from __future__ import annotations

import argparse
import base64
import json
import pathlib
import re
import textwrap
import xml.etree.ElementTree as ET


FILE_RE = re.compile(
    r'<File\s+Location="(?P<location>[^"]+)"\s+Permission="(?P<permission>[^"]+)"\s*/>'
)


def build(sopm: pathlib.Path, output: pathlib.Path) -> int:
    package_root = sopm.parent
    source = sopm.read_text(encoding="utf-8")
    definition = ET.fromstring(source)
    version = tuple(int(n) for n in definition.findtext('Version', '0.0.0').split('.'))
    if definition.findtext('Name') == 'TESSERA-Base' and version >= (0, 0, 184):
        for entry in definition.findall('./Filelist/File'):
            location = pathlib.PurePosixPath(entry.get('Location', ''))
            if location.is_absolute() or '..' in location.parts or location.parts[0] in {'docs', 'examples'}:
                raise ValueError('TESSERA runtime package documentation/fixtures must use var/tessera, not new Home roots: ' + str(location))
    if definition.findtext('Name') == 'TESSERA-Base' and version >= (0, 0, 184):
        descriptor_path = 'var/governancedb/container_release.json'
        locations = {entry.get('Location') for entry in definition.findall('./Filelist/File')}
        if descriptor_path not in locations:
            raise ValueError('TESSERA container release descriptor must be packaged')
        descriptor = json.loads((package_root / descriptor_path).read_text(encoding='utf-8'))
        expected = definition.findtext('Version')
        if descriptor.get('package') != 'TESSERA-Base' or descriptor.get('version') != expected:
            raise ValueError('Container release descriptor version must match SOPM version ' + expected)
        origins = descriptor.get('upgrade_from')
        if not isinstance(origins, list) or not origins or any(not isinstance(v, str) or not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', v) for v in origins):
            raise ValueError('Container upgrade origins must be explicit version strings')
        if len(set(origins)) != len(origins) or any(tuple(map(int, v.split('.'))) >= version for v in origins):
            raise ValueError('Container upgrade origins must be unique older releases')
    count = 0

    def embed(match: re.Match[str]) -> str:
        nonlocal count
        location = match.group("location")
        permission = match.group("permission")
        payload_path = package_root / pathlib.PurePosixPath(location)
        if not payload_path.is_file():
            raise FileNotFoundError(f"SOPM payload does not exist: {payload_path}")
        encoded = base64.b64encode(payload_path.read_bytes()).decode("ascii")
        wrapped = "\n".join(textwrap.wrap(encoded, width=76))
        count += 1
        return (
            f'<File Location="{location}" Permission="{permission}" Encode="Base64">'
            f'{wrapped}</File>'
        )

    package = FILE_RE.sub(embed, source)
    if count == 0:
        raise RuntimeError("No self-closing SOPM File entries were found.")

    ET.fromstring(package)
    output.write_text(package, encoding="utf-8", newline="\n")
    return count


def main() -> None:
    parser = argparse.ArgumentParser(description="Build an OTOBO OPM with byte-exact Base64 payloads.")
    parser.add_argument("sopm", type=pathlib.Path)
    parser.add_argument("output", type=pathlib.Path)
    args = parser.parse_args()
    count = build(args.sopm.resolve(), args.output.resolve())
    print(f"Built {args.output} with {count} Base64 payloads.")


if __name__ == "__main__":
    main()
