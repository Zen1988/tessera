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
