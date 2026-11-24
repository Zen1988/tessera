# Rebuild manually updated mounted configuration

After current XML definitions have been copied into the shared generated-config
PVC at /opt/otobo/Kernel/Config/Files/XML, run the native rebuild once against
that mounted directory. Copying files into /opt/tessera on the Kubernetes host
alone does not update the PVC. Keep the existing Config.pm Secret unchanged.
Do not copy host-generated ZZZAAuto.pm, ZZZACL.pm or ZZZProcessManagement.pm.

The configure.py helper seeds image definitions before rebuilding. For this
manual XML update, invoke the console directly so it uses the copied definitions.
Disable backend and memory cache only within the rebuild process so native
SysConfig reconciliation reads the current database rows.

Run on the Kubernetes host:

```bash
bash <<'REBUILD_SCRIPT'
set -euo pipefail

kubectl -n tessera exec -i deployment/tessera-web \
    -c tessera-web -- \
    /usr/bin/perl -I/opt/otobo/Custom \
    -I/opt/otobo/Kernel/cpan-lib -I/opt/otobo - <<'PERL'
use strict;
use warnings;
use Kernel::System::ObjectManager;
local $Kernel::OM = Kernel::System::ObjectManager->new();
$Kernel::OM->Get('Kernel::System::Cache')->Configure(
    CacheInBackend => 0,
    CacheInMemory  => 0,
);
exit $Kernel::OM->Get('Kernel::System::Console::InterfaceConsole')->Run(
    'Maint::Config::Rebuild',
    '--deploy-acls',
    '--deploy-processes',
);
PERL

kubectl -n tessera exec deployment/tessera-web \
    -c tessera-web -- \
    /opt/otobo/bin/otobo.Console.pl Maint::Cache::Delete

kubectl -n tessera rollout restart \
    deployment/tessera-web deployment/tessera-daemon

kubectl -n tessera rollout status deployment/tessera-web --timeout=600s
kubectl -n tessera rollout status deployment/tessera-daemon --timeout=600s
REBUILD_SCRIPT
```

Failure stops subsequent commands. Inspect the output before retrying.
This does not reinstall packages or run framework schema migrations.
