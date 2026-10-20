# syntax=docker/dockerfile:1
# Required: verified existing TESSERA179 base image pinned by digest.
# Build context: sanitized outputs/build-180/container.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.title="TESSERA" \
      org.opencontainers.image.version="0.0.180"
COPY --chown=0:0 --chmod=0644 Custom/Kernel/System/Cache/Redis.pm /opt/otobo/Custom/Kernel/System/Cache/Redis.pm
COPY --chown=0:0 --chmod=0644 Custom/Kernel/System/TESSERA/Secrets.pm /opt/otobo/Custom/Kernel/System/TESSERA/Secrets.pm
COPY --chown=0:0 --chmod=0644 Custom/Kernel/System/TESSERA/SecretRedis.pm /opt/otobo/Custom/Kernel/System/TESSERA/SecretRedis.pm
# Verify existing entrypoint uses this upstream first-copy tree before building.
COPY --chown=0:0 --chmod=0644 Custom/Kernel/System/Cache/Redis.pm /opt/otobo_install/otobo_next/Custom/Kernel/System/Cache/Redis.pm
COPY --chown=0:0 --chmod=0644 Custom/Kernel/System/TESSERA/Secrets.pm /opt/otobo_install/otobo_next/Custom/Kernel/System/TESSERA/Secrets.pm
COPY --chown=0:0 --chmod=0644 Custom/Kernel/System/TESSERA/SecretRedis.pm /opt/otobo_install/otobo_next/Custom/Kernel/System/TESSERA/SecretRedis.pm
COPY --chown=0:0 --chmod=0644 TESSERA-Base-0.0.180.opm /opt/tessera/releases/TESSERA-Base-0.0.180.opm
# Inherit ENTRYPOINT, CMD and USER. No configuration, secrets, install/DB hooks.
