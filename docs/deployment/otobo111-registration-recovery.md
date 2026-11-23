# Recover Base registration after packet-limit failure

Verified incident: all25 native DBUpdate-to-11.1 tasks finished, Base0.1.10
RepositoryAdd failed on max_allowed_packet, package_repository has ZERO Base
rows, and the original state remains APPLYING. MariaDB global packet limit is
now134217728 (128MiB). The native upgrader deleted the0.1.9 registry row before
its failed insert; retrying Upgrade with no installed row can invoke a fresh
PackageInstall. Do not run a fresh install, rerun native migration, reset phase,
or start application services.

## Use the bounded recovery

Extract this helper ZIP into the existing ~/upgrade directory, replacing the
Python upgrade helper. Keep the existing0.1.10 OPM and original state/backups.

    sudo python3 recover-otobo111-package-registration.py \
      --state /opt/otobo-update/tessera-11.1.1 \
      --tessera-package ./TESSERA-Base-0.1.10.opm \
      --migration-completed

The last flag records the already observed Migration finished output; it is
not permission to skip an incomplete native migration on another machine.

The recovery verifies exact old/target OPM hashes, native Package implementation,
stable version, unchanged Config.pm, all37 staged runtime hashes, original backup
checksums and stopped writers. It requires the native source-article index and
transactional package_repository storage. It restores ONLY the saved0.1.9 package
content/status through native RepositoryAdd in a transaction and verifies the
round trip. No files, install/upgrade SQL blocks, defaults or package hooks are
executed during this metadata restore. An existing identical0.1.9 entry is
accepted idempotently; a different or partially installed target is rejected.

It then runs native0.1.9->0.1.10 Upgrade, other-package repair, final Base reinstall
and target/repository checks, followed by configuration/translations/loader/cache
rebuild. It never repeats DBUpdate-to-11.1 or the core-source copy. Original
service/crontab state is retained. Success writes UPDATED_STOPPED.

Only after success:

    sudo python3 upgrade-otobo111-source.py start \
      --state /opt/otobo-update/tessera-11.1.1

If recovery stops, preserve the output/state. Do not force or switch to Install.
The registry may have advanced to0.1.10 before a later failure; that case needs
inspection and is deliberately outside this registration-only retry.

## Persist the packet limit without a restart now

SET GLOBAL affected new connections but does not survive a restart. The supplied
99-tessera-packet.cnf sets128M for the native MariaDB server. On the standard
Ubuntu configuration, install it only if the destination does not already exist:

    if sudo test -e /etc/mysql/mariadb.conf.d/99-tessera-packet.cnf; then
      sudo cat /etc/mysql/mariadb.conf.d/99-tessera-packet.cnf
    else
      sudo install -m 644 99-tessera-packet.cnf \
        /etc/mysql/mariadb.conf.d/99-tessera-packet.cnf
    fi

If a file already exists, review its setting rather than overwriting it.
Do not restart MariaDB during this recovery; the running128MiB global value
is already sufficient. New attempts now check the application's actual packet
limit before stopping services and record PACKAGES_UPGRADING after native
migration succeeds. The0.1.10 OPM and earlier release bundles remain unchanged.

Tests exercise the actual Perl metadata program with isolated DB/package
fixtures, including commit/rollback, corrupt content, existing records and
missing schema/engine gates. No Linux database recovery has been performed by
the agent. Kubernetes remains separate.
