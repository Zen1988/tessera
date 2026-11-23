# Native Ubuntu: OTOBO beta to 11.1.1 with TESSERA

This bundle upgrades the existing Ubuntu source/build host, then installs the
merged TESSERA-Base 0.1.10. Kubernetes stays on the separate container-kit route.
Do not install 0.1.10 on beta first; its native framework minimum is 11.1.1.

## Reviewed migration

All38 entries from the supplied source-host report are accounted for:37 runtime
files merged onto official11.1.1 and the preserved TESSERA README. The15 extra
Custom sources were supplied and matched to the recorded SHA256 values.
The package manifest binds every reviewed original/native/merged hash. Unknown
site changes fail before downtime; do not edit reviewed flags or force checks.
Previous release OPMs are unchanged. This is a prepared artifact, not a claim of
successful Linux migration or live browser/integration acceptance.

The official rel-11_1_1 source commit is
18feea896ab92138b5e8c4cd785ab4e198eccb1b. The supplied GitHub source archive hash is
347cfa9734f9b11f718bd2a8dd8b796256e3c6f98dc8924dc1bb7e82ac67a8b6.
The FTP tarball has different packing; do not substitute it for this pinned file.

## Continue from your existing prepared state

Extract the new compatibility-upgrade bundle into a fresh directory on the
Ubuntu host. It contains the updated helper and TESSERA-Base-0.1.10.opm.
The large official source archive is not duplicated: your existing state already
contains the verified source. Keep that state and its exported installed OPM.
Review module-check.txt under the state directory and install required missing
Perl modules first. Net::LDAP is required for this site's LDAP backend.
Stable11.1 uses Gnuplot for report charts. Install its headless executable before
apply (the matching container toolkit includes this dependency):

    sudo apt-get install gnuplot-nox

Take/test a VM/database snapshot first. Confirm all OTOBO writers are covered,
including remote integrations, schedulers and workers. The default service list
covers Apache, cron, Postfix and optional OTOBO web/daemon units. If different,
supply the complete comma-separated --services list. Back up /etc/apache2, TLS,
systemd and external data separately; the helper archives /opt/otobo only.
External/symlink article storage needs a site-specific backup plan.

Database tools default to root's local MariaDB socket authentication. Alternatively
use --db-defaults-file pointing to a root-owned mode600 MariaDB client option file.
No passwords belong on the command line. --db-name must equal the application's
configured DB; the helper checks this and requires InnoDB tables before shutdown.
Use your configured name if it differs from the example below.

    sudo python3 upgrade-otobo111-source.py apply \
      --state /opt/otobo-update/tessera-11.1.1 \
      --db-name otobo \
      --tessera-package ./TESSERA-Base-0.1.10.opm \
      --confirm-modules

The updated helper checks the exact38 prepared entries against the new package;
no report edits/re-preparation are needed for the unchanged source host. It checks
source/config/installed-package hashes and backup space, records active services
and the otobo crontab, then quiesces writers. Full application ACL/xattr and database
backups/checksums complete before any live source replacement.

It overlays pinned stable source, stages the merged runtime before DB migration,
runs DBUpdate-to-11.1, upgrades TESSERA0.1.10, repairs installed packages, then
reinstalls0.1.10 last and verifies every merged target and repository content.
This prevents repair of another package from leaving an older shared Custom file
in use. It rebuilds configuration, translations, cache and loader assets.
It does not run a fresh installer, delete governance/ticket data, fetch arbitrary
online upgrades, force incompatible packages or replace native service/TLS setup.
The separate experimental beta-version-comparison bridge is excluded.

Successful apply records UPDATED_STOPPED and deliberately leaves services stopped.
Inspect migration/package output, then:

    sudo python3 upgrade-otobo111-source.py start \
      --state /opt/otobo-update/tessera-11.1.1

Start restores only the saved active services/legacy daemon and saved crontab.
Verify fresh agent/customer login, CMDB entitlement, account/LDAP behavior,
Dynamic Field Sets/Lens/import-export, ticket lifecycle, announcements, Navis/AWX
and loader assets. Verify effective SysConfig/theme/cache settings after upstream
migration. Then use the matching0.1.10 container toolkit from a fresh directory
against the accepted /opt/otobo source for the separate K8s image/bundle build.
That builds the image; it does not migrate a separate Kubernetes database.
The current deployment wrapper upgrades TESSERA packages/configuration but does
not invoke native DBUpdate-to-11.1. A beta-based K8s database therefore needs its
own backed-up native framework migration before this stable image is rolled out.

## New preparation, only if the source has changed

Use a NEW state directory; do not overwrite the previous one:

    sudo python3 upgrade-otobo111-source.py prepare \
      --home /opt/otobo \
      --state /opt/otobo-update/tessera-11.1.1-new \
      --archive ./otobo-11.1.1-source.tar.gz

Preparation supports11.1.0 beta1/beta2/beta3, but automatic package approval applies
only when every actual report entry matches this reviewed source profile. Changed
or additional site overrides need an explicit compatibility merge first.

## Failure and rollback

Any error after shutdown leaves maintenance in place. Preserve logs/state/backups.
Do not rerun apply on a partial state or force start. Migration/hook retries need
inspection. Restore the MATCHED database and full tree, plus external/service
configuration, from the same quiesced backup point. Verify backup-sha256.json.
Keep all writers stopped. Preserve the failed tree for diagnosis, restore the
file archive with ACLs/xattrs to the original parent, and restore the SQL dump
to a CLEAN database through a tested DBA/VM recovery procedure. A blind import
into an existing schema can retain tables added by the new release. Restore the
saved crontab/prior services only after verifying the restored pair.

## Official references

- [Stable release notes](https://otobo.io/en/otobo-11-1/)
- [Ubuntu update procedure](https://doc.otobo.org/manual/installation/11.1/en/content/updating/updating-ubuntu.html)
- [Official source tag](https://github.com/RotherOSS/otobo/tree/rel-11_1_1)
- [Ubuntu26.04 headless Gnuplot package](https://packages.ubuntu.com/resolute/gnuplot-nox)

The Ubuntu guide still shows beta2 example filenames. This helper explicitly pins
stable11.1.1 and adds TESSERA compatibility binding and controlled package repair.
