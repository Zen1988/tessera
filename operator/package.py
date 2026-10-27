"""Package only reviewed source files; never include local credentials or dependencies."""
import hashlib
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parent
files = ["README.md", "Dockerfile", ".dockerignore", ".gitignore", "requirements.txt",
         "monitor.py", "config.example.json", "k8s.yaml", "build.sh", "build-containerd.sh", "CONTAINERD.md", "package.py",
         "tests/test_build_context.py", "tests/test_packaging.py", "tests/test_monitor.py", "tests/test_build_containerd.sh",
         "render_ncs_manifest.py", "k8s-ncs-observe.yaml", "recovery.py", "redis_recovery.py", "tests/test_redis_recovery.py", "REDIS.md", "redis-policy.example.json", "redis-policy-ncs.json", "longhorn_recovery.py", "longhorn-policy-ncs.json", "LONGHORN.md", "recovery-longhorn-rbac.yaml", "tests/test_longhorn_recovery.py", "configure-redis.py", "inspect-recovery.sh", "recovery-redis-rbac.yaml", "ha-ncs-deployment-patch.yaml", "tests/test_api_failover.py", "RECOVERY.md",
         "tests/test_recovery.py", "render_recovery_manifest.py", "recovery-ncs-rbac.yaml",
         "recovery-galera-rbac.yaml", "recovery-config-patch.json", "recovery-deployment-patch.yaml"]
VERSION = "0.3.5"


def package(output=None, source_root=None):
    source_root = Path(source_root) if source_root is not None else root
    output = Path(output) if output is not None else root.parent / "outputs" / f"TESSERA-Operator-{VERSION}-Build-Kit.zip"
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for name in files:
            payload = (source_root / name).read_bytes()
            mode = 0o644
            if name.endswith(".sh"):
                # Windows working trees/editors may reintroduce CRLF or a UTF-8 BOM.
                text = payload.decode("utf-8-sig").replace("\r\n", "\n").replace("\r", "\n")
                if not text.startswith("#!/"):
                    raise ValueError("shell script is missing its shebang: " + name)
                payload = text.encode("utf-8")
                mode = 0o755
            info = zipfile.ZipInfo(f"tessera-operator-{VERSION}/" + name)
            info.create_system = 3
            info.external_attr = (0o100000 | mode) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, payload)
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(output.suffix + ".sha256").write_bytes((digest + "  " + output.name + "\n").encode())
    return output, digest


if __name__ == "__main__":
    output, digest = package()
    print(str(output))
    print(digest)
