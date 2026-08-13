from __future__ import annotations

import argparse
import base64
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
