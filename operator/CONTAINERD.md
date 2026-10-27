# Build on zen@10.0.1.61 using containerd

Owner-reported host: `x86_64`, `/usr/bin/ctr`; no Docker, nerdctl or buildctl. Password login is available in the owner's separate SSH window, not in the agent's noninteractive SSH session. No installation/build/import has been executed remotely by this kit.

BuildKit can build the existing Dockerfile directly and export OCI archives. No Docker/nerdctl installation or containerd restart is required. This uses a separate BuildKit socket/state directory and containerd namespace `tessera-buildkit`. Build cache consumes this host's disk; choose capacity accordingly. Nothing here deploys Kubernetes workloads or modifies existing services.

## 1. Transfer the updated kit

Run in a LOCAL PowerShell window (enter the SSH password there):

```powershell
scp 'C:\Users\Zen\OneDrive\Documents\TESSERA\outputs\TESSERA-Operator-0.3.5-Build-Kit.zip' 'C:\Users\Zen\OneDrive\Documents\TESSERA\outputs\TESSERA-Operator-0.3.5-Build-Kit.zip.sha256' zen@10.0.1.61:~/
```

On the remote host:

```sh
cd "$HOME"
sha256sum -c TESSERA-Operator-0.3.5-Build-Kit.zip.sha256
unzip -n TESSERA-Operator-0.3.5-Build-Kit.zip
```

Use a fresh directory if an older `tessera-operator` directory already exists: `unzip -n` deliberately does not overwrite existing source. `unzip`, `curl`, `tar` and standard coreutils are prerequisites. Do not mix kit revisions.

## 2. Install just the two BuildKit executables

Official BuildKit **v0.34.1**, Linux amd64. SHA256 below was retrieved from the official GitHub release API on 2026-10-22. The archive also contains optional OCI runtime executables; do not install those over the host's existing runtime.

```sh
stage=$(mktemp -d "$HOME/tessera-buildkit.XXXXXX")
cd "$stage"
curl --fail --location --proto '=https' --tlsv1.2 \
  -o buildkit.tar.gz \
  https://github.com/moby/buildkit/releases/download/v0.34.1/buildkit-v0.34.1.linux-amd64.tar.gz
printf '%s\n' 'a59539daf547fe0958efe2d07e41c0a6944e1112a66d7e519ec1cf5b673ef15b  buildkit.tar.gz' | sha256sum -c -
tar -xzf buildkit.tar.gz bin/buildctl bin/buildkitd
test ! -e /usr/local/bin/buildctl
test ! -e /usr/local/bin/buildkitd
sudo install -m 0755 bin/buildctl /usr/local/bin/buildctl
sudo install -m 0755 bin/buildkitd /usr/local/bin/buildkitd
```

Execute these as sequential commands and stop if any fail, especially checksum/existing-file checks. Existing binaries should be inspected, not overwritten. This kit does not configure a boot service or change the containerd config.

## 3. Start the isolated builder

In remote terminal 1, leave this running in the foreground:

```sh
sudo /usr/local/bin/buildkitd \
  --addr unix:///run/tessera-buildkit/buildkitd.sock \
  --root /var/lib/tessera-buildkit \
  --oci-worker=false \
  --containerd-worker=true \
  --containerd-worker-addr /run/containerd/containerd.sock \
  --containerd-worker-namespace tessera-buildkit
```

The containerd socket above is the conventional default, not verified on this host. If it differs, use the socket used by the working `ctr` command. Verify BuildKit reports a worker before continuing. Default CNI/build networking must permit HTTPS package/base-image downloads; do not disable TLS checks if networking fails. BuildKit's containerd worker requires compatible containerd/runtime plugins; diagnose errors without restarting production containerd.

## 4. Build and import

In remote terminal 2:

```sh
cd "$HOME/tessera-operator-0.3.5"
sudo env PATH="/usr/local/bin:$PATH" sh build-containerd.sh
sudo ctr --namespace k8s.io images import dist/tessera-operator-image.oci.tar
sudo ctr --namespace k8s.io images list | grep tessera-operator
```

Build output must show the embedded test suite and config validation succeeding. The archive, SHA256, build metadata and image reference are in `dist/`. Default reference is `docker.io/library/tessera-operator:0.3.5`; no registry push occurs. Kubernetes namespace `apps` and containerd image namespace `k8s.io` are unrelated. Local import makes the image available only on this node. Import on every eligible Kubernetes node or deliberately publish to an internal registry before deployment. `ctr images import` is an explicit local image-store change, not a rollout.

## 5. Validate the final image without deploying it

```sh
cd "$HOME/tessera-operator-0.3.5"
sudo ctr --namespace k8s.io run --rm --read-only \
  --mount "type=bind,src=$PWD/config.example.json,dst=/etc/tessera-operator/config.json,options=rbind:ro" \
  docker.io/library/tessera-operator:0.3.5 \
  "tessera-operator-validate-$(date +%s)" \
  python /app/monitor.py --validate
```

Expect `configuration valid` and exit code 0. This exercises final-image execution and Linux config validation only; no credentials or live endpoint checks are used. Root filesystem is read-only, UID65532 comes from the image. The command does not use host networking. Stop the BuildKit foreground process with Ctrl+C once builds finish; do not stop containerd. Preserve the OCI archive and metadata for deployment acceptance.

Deployment remains a separate step described in README.md. The baseline is observe-only, internal to `apps`, with no own DB/PVC or externally exposed Service. Recovery/scale/write actions remain unimplemented.

References: [BuildKit usage and exporters](https://github.com/moby/buildkit/blob/master/README.md), [official release](https://github.com/moby/buildkit/releases/tag/v0.34.1), [release asset metadata](https://api.github.com/repos/moby/buildkit/releases/tags/v0.34.1).

## Build-kit corrections in0.3.5

0.3.2 ZIP shipped CRLF shell scripts and an outdated Docker context allowlist. The first prevented sh from parsing set -eu; after line-ending repair, the second excluded Redis/Longhorn source and newer tests from COPY. Version0.3.5 normalizes packaged shell files to UTF-8 without BOM/LF, stores executable permissions, and explicitly admits all Docker COPY inputs and Python tests. Regression tests cover both. Earlier0.3.2 archive is preserved for provenance; use a freshly extracted0.3.5 kit for the corrected build.

An existing extracted0.3.2 directory can be repaired with:

```sh
sed -i 's/\r$//' build-containerd.sh build.sh inspect-recovery.sh
cat >> .dockerignore <<'EOF'

!redis_recovery.py
!longhorn_recovery.py
!redis-policy-ncs.json
!tests/*.py
EOF
sudo env PATH="/usr/local/bin:$PATH" sh ./build-containerd.sh
```

Import dist/tessera-operator-image.oci.tar only after a successful build. Image tags differ: repaired0.3.2 remains0.3.2; the fresh0.3.5 kit produces0.3.5. Do not apply a newer deployment patch to an older-tagged image.
