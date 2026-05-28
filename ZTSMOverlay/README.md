# ZTSM Overlay

This folder keeps ZTSM customizations separate from the upstream OTOBO tree.

Use it after refreshing `Kernel` from a newer OTOBO release:

```powershell
perl ZTSMOverlay/bin/ztsm-overlay.pl --root . --check
perl ZTSMOverlay/bin/ztsm-overlay.pl --root . --apply
```

Overlay rules:

- `copy` entries are ZTSM-owned files and can be copied over directly.
- `patch` entries are edits inside upstream OTOBO files and are applied with `git apply --3way`.
- If a patch conflicts after an OTOBO security update, resolve that conflict manually instead of replacing the whole upstream file.

Package Manager code is intentionally not owned by this overlay. Keep it close to upstream so real OTOBO packages and repositories continue to work.
