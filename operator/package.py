"""Package only reviewed source files; never include local credentials or dependencies."""
import hashlib
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parent
files = ["README.md", "Dockerfile", ".dockerignore", ".gitignore", "requirements.txt",
         "monitor.py", "config.example.json", "k8s.yaml", "build.sh", "build-containerd.sh", "CONTAINERD.md", "package.py",
         "tests/test_monitor.py", "tests/test_build_containerd.sh",
         "render_ncs_manifest.py", "k8s-ncs-observe.yaml", "recovery.py", "redis_recovery.py", "tests/test_redis_recovery.py", "REDIS.md", "redis-policy.example.json", "redis-policy-ncs.json", "longhorn_recovery.py", "longhorn-policy-ncs.json", "LONGHORN.md", "recovery-longhorn-rbac.yaml", "tests/test_longhorn_recovery.py", "configure-redis.py", "inspect-recovery.sh", "recovery-redis-rbac.yaml", "ha-ncs-deployment-patch.yaml", "tests/test_api_failover.py", "RECOVERY.md",
         "tests/test_recovery.py", "render_recovery_manifest.py", "recovery-ncs-rbac.yaml",
         "recovery-galera-rbac.yaml", "recovery-config-patch.json", "recovery-deployment-patch.yaml"]
output = root.parent / "outputs" / "TESSERA-Operator-0.3.2-Build-Kit.zip"
output.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
    for name in files:
        archive.write(root / name, "tessera-operator-0.3.2/" + name)
digest = hashlib.sha256(output.read_bytes()).hexdigest()
output.with_suffix(output.suffix + ".sha256").write_text(digest + "  " + output.name + "\n")
print(str(output))
print(digest)
