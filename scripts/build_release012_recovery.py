"""Build the exact-incident recovery code bundle; never include live credentials."""
import base64
import hashlib
import json
from pathlib import Path
import re
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "container/ubuntu2604"


def main():
    archive = ROOT / ".artifacts/otobo111/github-11.1.1.tar.gz"
    assert hashlib.sha256(archive.read_bytes()).hexdigest() == "347cfa9734f9b11f718bd2a8dd8b796256e3c6f98dc8924dc1bb7e82ac67a8b6"
    with tarfile.open(archive) as tar:
        files = {m.name.split("/", 1)[1]: tar.extractfile(m).read()
                 for m in tar.getmembers() if m.isfile()
                 and ("/scripts/DBUpdateTo11_1/" in m.name or m.name.endswith("/scripts/DBUpdateTo11_1.pm"))}
    tasks = re.findall(r"Module\s*=>\s*'([^']+)'", files["scripts/DBUpdateTo11_1.pm"].decode())
    assert len(tasks) == 25
    manifest = {"framework": "11.1.1", "tasks": tasks,
                "files": {n: hashlib.sha256(d).hexdigest() for n, d in files.items()}}
    (KIT / "image/framework-11.1.1.json").write_text(json.dumps(manifest, indent=2) + "\n", newline="\n")
    source = (KIT / "scripts/recover-navis017.py").read_text()
    source = source.replace("import argparse", "import argparse\nimport base64", 1)
    source = source.replace("diagnostic = load('config_resume_diagnostic', HERE / 'diagnose-release.py')",
        "diagnostic = load('config_resume_diagnostic', HERE / 'diagnose-release.py')\n"
        "preflight = load('release012_preflight', HERE / 'recovery-preflight.py')")
    source = source.replace("One-attempt one-attempt reviewed post-hook completion for the verified0.1.7 failure.",
                            "One-attempt recovery of the reviewed testing0.1.8->0.1.12 partial upgrade.")
    source = source.replace("tessera-release-1795404303", "tessera-release-1795491815")
    source = source.replace("Only the reviewed failed0.1.7 Job may recover", "Only the reviewed failed0.1.12 Job may recover")
    source = source.replace("navis017", "release012").replace("Navis017", "Release012")
    source = source.replace("main['args'] = [CONTROL]", "main['args'] = [base64.b64encode(CONTROL.encode()).decode()]")
    source = source.replace("main.setdefault('env', []).append({'name': 'TESSERA_UPGRADE_QUIESCED', 'value': '1'})",
        "main.setdefault('env', []).extend([{'name': 'TESSERA_UPGRADE_QUIESCED', 'value': '1'}, "
        "{'name': 'TESSERA_TEST_NO_BACKUP', 'value': '1'}])")
    begin = source.index("    pod['volumes'][-1]['configMap']['items']")
    end = source.index("    return result", begin)
    source = source[:begin] + """    pod['volumes'][-1]['configMap']['items'] = [
        {'key': name, 'path': name} for name in (
            'configure.py', 'recover-release012.pl', 'upgrade-cache.pl', 'framework-11.1.1.json')]
""" + source[end:]
    begin = source.index("        'configure.py': source,")
    end = source.index("}.items()}}", begin)
    source = source[:begin] + """        'configure.py': source,
        'recover-release012.pl': HERE.parent/'image/recover-release012.pl',
        'upgrade-cache.pl': HERE.parent/'image/upgrade-cache.pl',
        'framework-11.1.1.json': HERE.parent/'image/framework-11.1.1.json'""" + source[end:]
    source = source.replace("Release0.1.7 READY", "Release0.1.12 READY")
    assert source.count("    return result") == 1
    source = source.replace("    return result",
        "    result['spec']['activeDeadlineSeconds'] = 3600\n    return result", 1)
    source = source.replace("time.monotonic() + 660", "time.monotonic() + 3660")
    source = source.replace("out.mkdir(mode=0o700, exist_ok=False)",
        "\n    if out.exists(): raise ValueError('Recovery already attempted; inspect saved state before retry')")
    source = source.replace("    save('failed-job.json', failed);",
        """    def validate_quiet():
        observed = client.get('configmap', helper.LOCK_NAME)
        if observed.get('data') != claim.get('data'):
            raise ValueError('Original maintenance ownership changed')
        for old in workloads:
            current = client.get('deployment', old['metadata']['name'])
            common.same_target(current, old)
            if current['spec'].get('replicas', 1) != 0 or current['spec']['template']['spec']['containers'][0]['image'] != old['spec']['template']['spec']['containers'][0]['image']:
                raise ValueError('Target workloads changed during preflight')
            if helper.workload_pods(client.get('pods', '-l', helper.selector(old))['items']):
                raise ValueError('Application writers remain')
        if any(h['spec']['scaleTargetRef']['name'] in names for h in client.get('hpa')['items']):
            raise ValueError('HPA ownership changed')
        for other in client.get('jobs')['items']:
            if other['spec']['template']['metadata'].get('labels', {}).get('tessera-release-upgrade') and not (common.terminal(other, 'Complete') or common.terminal(other, 'Failed')):
                raise ValueError('Another release/diagnostic Job is active')
        return observed
    lock = preflight.run(client, state, manifest, code, validate_quiet)
    out.mkdir(mode=0o700, exist_ok=False)
    save('failed-job.json', failed);""")
    source = source.replace("owned();client.write(code);owned();client.write(manifest)",
                            "owned();client.write(manifest)")
    source = source.replace("parser.add_argument('--state-directory', type=Path)",
        "parser.add_argument('--state-directory', type=Path)\n"
        "    parser.add_argument('--test-no-backup', action='store_true', required=True,\n"
        "                        help='Owner-approved test-server recovery without backup')")
    source = source.replace("    _, observed_pvc = before.validate_manifest(failed)",
        "    if main['image'] != 'docker.io/library/tessera:0.1.12-ubuntu26.04':\n"
        "        raise ValueError('Requires the original reviewed0.1.12 image')\n"
        "    _, observed_pvc = before.validate_manifest(failed)")
    source = source.replace("    if out.exists(): raise ValueError('Recovery already attempted; inspect saved state before retry')",
        "    if out.exists(): preflight.preserve_unclaimed(client, out, failed, lambda old_name: recovery_manifest(failed, namespace, old_name))")
    source = source.replace("    client.write(code, dry=True);client.write(manifest, dry=True)",
        "    client.write(manifest, dry=True)")
    target = KIT / "scripts/recover-release012.py"
    target.write_text(source, encoding="utf-8", newline="\n")
    payload = {}
    for name in ("recover-release012.py", "upgrade-deploy.py", "recover-179-to-184.py",
                 "resume-before-upgrade.py", "diagnose-release.py", "recovery-preflight.py"):
        payload["scripts/" + name] = (KIT / "scripts" / name).read_bytes().replace(b"\r\n", b"\n")
    for name in ("recover-release012.pl", "upgrade-cache.pl", "framework-11.1.1.json", "configure.py",
                 "package-inventory.pl", "package-reconcile.pl"):
        payload["image/" + name] = (KIT / "image" / name).read_bytes().replace(b"\r\n", b"\n")
    payload["README.md"] = (ROOT / "docs/deployment/release012-recovery.md").read_bytes()
    payload["SHA256SUMS"] = "".join(hashlib.sha256(d).hexdigest() + "  " + n + "\n"
                                    for n, d in sorted(payload.items())).encode()
    output = ROOT / "outputs/TESSERA-0.1.12-LabelPrint-Recovery-r3.zip"
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as zip_file:
        for name, data in sorted(payload.items()):
            info = zipfile.ZipInfo(name, (2026, 11, 24, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            zip_file.writestr(info, data)
    sha = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(".zip.sha256").write_text(sha + "  " + output.name + "\n", newline="\n")
    with zipfile.ZipFile(output) as z:
        assert z.testzip() is None
    print(json.dumps({"sha256": sha, "files": len(payload), "framework_tasks": len(tasks)}))


if __name__ == "__main__":
    main()
