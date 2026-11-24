"""Separate read-only DB preflight; never transfers maintenance ownership."""
import copy
import json
import os
import time
import uuid


def run(client, state, manifest, code, validate):
    validate()
    job = copy.deepcopy(manifest)
    name = manifest["metadata"]["name"] + "-check"
    job["metadata"]["name"] = name
    job["spec"]["activeDeadlineSeconds"] = 600
    job["spec"]["template"]["metadata"]["labels"]["tessera-release-upgrade"] = name
    main = job["spec"]["template"]["spec"]["containers"][0]
    main.setdefault("env", []).append({"name": "TESSERA_RECOVERY_CHECK_ONLY", "value": "1"})
    directory = state / ("preflight-release012-" + uuid.uuid4().hex[:12])
    directory.mkdir(mode=0o700)
    for filename, value in (("job.json", job), ("code.json", code)):
        path = directory / filename
        with path.open("x") as stream:
            os.chmod(path, 0o600)
            json.dump(value, stream, indent=2)
    client.write(code, dry=True)
    client.write(job, dry=True)
    client.write(manifest, dry=True)
    validate()
    client.write(code)
    client.write(job)
    print("Recovery preflight Job:", name, flush=True)
    deadline = time.monotonic() + 660
    while time.monotonic() < deadline:
        current = client.get("job", name)
        terminal = {c.get("type") for c in current.get("status", {}).get("conditions", [])
                    if c.get("status") == "True"}
        if terminal & {"Complete", "Failed"}:
            client.run("logs", "job/" + name, "-c", main["name"], "--tail=60")
            if "Failed" in terminal:
                raise ValueError("Preflight failed before recovery ownership/package changes; inspect output, correct prerequisites and retry")
            return validate()
        time.sleep(3)
    raise ValueError("Preflight not terminal; preserve evidence and inspect before retry")


def preserve_unclaimed(client, out, original, expected_manifest):
    """Archive only the exact r2 local staging failure; never remove recovery claims."""
    required = {"failed-job.json", "upgrade-job.json", "bundle-pvc.json", "rebuild-code.json"}
    if out.is_symlink() or {p.name for p in out.iterdir()} != required:
        raise ValueError("Existing recovery has claim/unknown evidence; inspect before retry")
    data = {p.name: json.loads(p.read_text()) for p in out.iterdir()}
    manifest = data["upgrade-job.json"]
    name = manifest["metadata"]["name"]
    if name != "tessera-release012-recovery-bbb4eb07c318" or manifest != expected_manifest(name):
        raise ValueError("Existing staging is not the reviewed r2 preclaim failure")
    old = data["failed-job.json"]
    if old.get("metadata", {}).get("uid") != original.get("metadata", {}).get("uid") or old["spec"] != original["spec"]:
        raise ValueError("Staged original Job differs")
    jobs = client.get("jobs")["items"]
    if any(j["metadata"]["name"] == name for j in jobs):
        raise ValueError("Recovery Job exists; never replay")
    check = client.get("job", name + "-check")
    if not any(c.get("type") == "Complete" and c.get("status") == "True" for c in check.get("status", {}).get("conditions", [])):
        raise ValueError("Previous preflight not complete")
    container = check["spec"]["template"]["spec"]["containers"][0]
    if {"name": "TESSERA_RECOVERY_CHECK_ONLY", "value": "1"} not in container.get("env", []):
        raise ValueError("Previous Job was not check-only")
    code = data["rebuild-code.json"]
    live = client.get("configmap", code["metadata"]["name"])
    if not live.get("immutable") or live.get("data") != code.get("data"):
        raise ValueError("Previous code differs")
    archive = out.with_name(out.name + "-preclaim-r2-" + uuid.uuid4().hex[:12])
    out.rename(archive)
    print("Preserved unclaimed r2 staging:", archive, flush=True)
