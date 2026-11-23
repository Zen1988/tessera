# Build and controlled deployment

Install the target OPM normally on the source OTOBO host before preparing its image. Use a fresh current toolkit; keep generated image and upgrade bundle together. Copying XML alone does not create fields or run hooks.

```bash
sha256sum -c TESSERA-0.1.5-Ubuntu26.04-Container-Toolkit.zip.sha256
bash scripts/prepare.sh /opt/otobo
bash scripts/build.sh
```

Verify prepare reports 0.1.5. Use the actual tag in artifacts/latest-build.json. Import/publish the image using your established node registry flow and transfer the matching bundle. From the prepared build directory:

```bash
python3 scripts/deploy-release.py \
  --namespace tessera --web tessera-web --daemon tessera-daemon \
  --container tessera-web \
  --image docker.io/library/tessera:0.1.5-ubuntu26.04 \
  --bundle artifacts/upgrade-bundle
```

The wrapper creates a unique temporary PVC, validates/uploads the bundle, runs the controlled upgrade and restores saved replicas. Cleanup happens only after native success and both rollouts. Failures retain evidence. Do not use the old fixed-PVC/deploy195 flow.

If an upgrade is incomplete, use [recovery triage](recovery.md). Prepared artifacts are not proof of live installation. [Acceptance](../development/validation.md) includes fresh/upgrade/reinstall and all-worker activation.

