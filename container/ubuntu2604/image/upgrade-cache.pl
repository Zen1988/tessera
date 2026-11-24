#!/usr/bin/env perl
use strict;
use warnings;

# Upgrade-only, process-local policy. A cached pre-upgrade SysConfig list can
# omit rows already present in the DB and send native reconciliation down its
# insert path. Let native locking/update/versioning read authoritative rows.
# Runtime Redis settings, administrator overrides and SQL semantics stay native.
sub UpgradeCacheConfigure {
    my ($Cache) = @_;
    die "Upgrade cache configuration unavailable.\n" if !ref $Cache || !$Cache->can('Configure');
    $Cache->Configure(CacheInBackend => 0, CacheInMemory => 0);
    return 1;
}
1;
